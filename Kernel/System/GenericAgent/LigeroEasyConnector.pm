package Kernel::System::GenericAgent::LigeroEasyConnector;

use strict;
use warnings;

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

    #my @ArticleIndex = $TicketObject->ArticleGet(
    #    %Param,
    #    Order    => 'DESC', # DESC,ASC - default is ASC
    #    Limit    => 1,
    #);

    #use Data::Dumper;

    #$Kernel::OM->Get('Kernel::System::Log')->Log(
    #    Priority => 'error',
    #    Message  => "PARAM ".Dumper(@ArticleIndex[0]->{ArticleID}),
    #);

    

    my %Data = (
        'TicketID' => $Param{TicketID}
    );

    

    use Data::Dumper;

    

    # check needed param
    if ( $Param{New}->{'PreWebServiceName'} && $Param{New}->{'PreWebServiceInvoker'}) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "CHEGOU AQUI ".$Param{New}->{'PreWebServiceName'}." ".$Param{New}->{'PreWebServiceInvoker'},
        );
        my $WebService = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(
            Name => $Param{New}->{'PreWebServiceName'},
        );

         my $Result = $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
            WebserviceID => $WebService->{ID},
            Invoker      => $Param{New}->{'PreWebServiceInvoker'},
            Data         => \%Data
        );

        $Data{PreResult} = $Result;
    }

    if ( $Param{New}->{'PostWebServiceName'} && $Param{New}->{'PostWebServiceInvoker'}) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "CHEGOU AQUI Post ".$Param{New}->{'PostWebServiceName'}." ".$Param{New}->{'PostWebServiceInvoker'},
        );
        my $WebService = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(
            Name => $Param{New}->{'PostWebServiceName'},
        );

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
