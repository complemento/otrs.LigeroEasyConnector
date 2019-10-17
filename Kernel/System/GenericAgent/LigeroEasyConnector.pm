package Kernel::System::GenericAgent::LigeroEasyConnector;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicFieldBackend',
    'Kernel::System::Ticket',
    'Kernel::System::Time',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::GenericInterface::Requester',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    
    #Create system objects that will be used above
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');
    my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @ArticleIndex = $TicketObject->ArticleGet(
        %Param,
        Order    => 'DESC', # DESC,ASC - default is ASC
        Limit    => 2,
    );

    my $ArticleID;
    my %Article;
    for my $FileID ( @ArticleIndex ) {
        if($FileID->{SenderType} ne 'system' && !$ArticleID){
            $ArticleID = $FileID->{ArticleID};
            %Article = $FileID;
        }
    }
    
    my %Data = (
        'TicketID' => $Param{TicketID},
        'ArticleID' => $ArticleID
    );

    my $WebService = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(
        Name => $Param{New}->{'WebServiceName'},
    );

    # check needed param
    if ($Param{New}->{'PreWebServiceInvoker'}) {

        my $Result = $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
            WebserviceID => $WebService->{ID},
            Invoker      => $Param{New}->{'PreWebServiceInvoker'},
            Data         => \%Data
        );

        $Data{PreResult} = $Result;
    }

    # check needed param
    if ($Param{New}->{'WebServiceInvoker'}) {
        

        my $Result = $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
            WebserviceID => $WebService->{ID},
            Invoker      => $Param{New}->{'WebServiceInvoker'},
            Data         => \%Data
        );

        $Data{Result} = $Result;
    }

    # check needed param
    if ($Param{New}->{'WebServiceAttachmentInvoker'}) {
        
        my %Index = $TicketObject->ArticleAttachmentIndex(
            ArticleID                  => $ArticleID,
            UserID                     => 1,
            Article                    => \%Article,
            StripPlainBodyAsAttachment => 3,
        );

        FILE_UPLOAD:
        for my $FileID ( sort keys %Index ) {

            my %Attachment = $TicketObject->ArticleAttachment(
                ArticleID => $ArticleID,
                FileID    => $FileID,   # as returned by ArticleAttachmentIndex
                UserID    => 1,
            );

            if ($Param{New}->{'WebServiceAttachmentMaxSize'} && int($Index{$FileID}->{FilesizeRaw}) > int($Param{New}->{'WebServiceAttachmentMaxSize'})) {
                next FILE_UPLOAD;
            }

            my $dir = "/opt/otrs/var/tmp/";

            my $timestamp = int (gettimeofday * 1000);

            my $file = $dir.$timestamp.$Attachment{Filename};

            open(FH, '>', $file) or die $!;

            print FH $Attachment{Content};

            close(FH);

            my %UploadData = (
                'TicketID' => $Param{TicketID},
                'ArticleID' => $ArticleID,
                'FilePath' => $file,
                'FileData' => $Index{$FileID},
                'PreResult' => $Data{PreResult},
                'Result' => $Data{Result}
            );

            $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
                WebserviceID => $WebService->{ID},
                Invoker      => $Param{New}->{'WebServiceAttachmentInvoker'},
                Data         => \%UploadData
            );
        }
        
    }

    if ($Param{New}->{'PostWebServiceInvoker'}) {

        my $Result = $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
            WebserviceID => $WebService->{ID},
            Invoker      => $Param{New}->{'PostWebServiceInvoker'},
            Data         => \%Data
        );
    }

    #$Kernel::OM->Get('Kernel::System::Log')->Log(
    #    Priority => 'error',
    #    Message  => "aaaaaaaaaaaaaaaaaaaa -------",
    #);
}

1;
