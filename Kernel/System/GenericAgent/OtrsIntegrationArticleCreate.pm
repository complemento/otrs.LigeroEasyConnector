package Kernel::System::GenericAgent::OtrsIntegrationArticleCreate;

use strict;
use warnings;

use Kernel::System::DynamicField;
use Kernel::System::DynamicField::Backend;
use Kernel::System::GenericInterface::Webservice;
use Kernel::GenericInterface::Requester;
use Kernel::System::Ticket;

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
        Limit    => 1,
    );

    #use Data::Dumper;

    #$Kernel::OM->Get('Kernel::System::Log')->Log(
    #    Priority => 'error',
    #    Message  => "PARAM ".Dumper(@ArticleIndex[0]->{ArticleID}),
    #);

    

    my %Data = (
        'ArticleID' => @ArticleIndex[0]->{ArticleID}
    );

    my $WebService = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(
        Name => $Kernel::OM->Get('Kernel::Config')->Get('OTRSIntegration::WebServiceName'),
    );

    $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
        WebserviceID => $WebService->{ID},
        Invoker      => $Kernel::OM->Get('Kernel::Config')->Get('OTRSIntegration::InvokerNameArticleCreate'),
        Data         => \%Data
    );

    #$Kernel::OM->Get('Kernel::System::Log')->Log(
    #    Priority => 'error',
    #    Message  => "aaaaaaaaaaaaaaaaaaaa -------",
    #);
}

1;