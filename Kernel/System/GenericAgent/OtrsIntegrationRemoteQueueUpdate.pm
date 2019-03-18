package Kernel::System::GenericAgent::OtrsIntegrationRemoteQueueUpdate;

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

    #use Data::Dumper;

    #$Kernel::OM->Get('Kernel::System::Log')->Log(
    #    Priority => 'error',
    #    Message  => "ENTROU AQUI",
    #);

    my $WebService = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(
        Name => $Kernel::OM->Get('Kernel::Config')->Get('OTRSIntegration::WebServiceName'),
    );

    $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
        WebserviceID => $WebService->{ID},
        Invoker      => $Kernel::OM->Get('Kernel::Config')->Get('OTRSIntegration::InvokerNameRemoteQueueUpdate'),
        Data         => \%Param
    );

    #$Kernel::OM->Get('Kernel::System::Log')->Log(
    #    Priority => 'error',
    #    Message  => "aaaaaaaaaaaaaaaaaaaa -------",
    #);
}

1;
