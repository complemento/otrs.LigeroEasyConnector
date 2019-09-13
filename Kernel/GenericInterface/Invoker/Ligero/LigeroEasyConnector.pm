package Kernel::GenericInterface::Invoker::Ligero::LigeroEasyConnector;

use strict;
use warnings;

use Data::Dumper;

use utf8;
use Encode qw( encode_utf8 );

use MIME::Base64 qw(encode_base64 decode_base64);

use Kernel::System::VariableCheck qw(IsString IsStringWithData);

# prevent 'Used once' warning for Kernel::OM
use Kernel::System::ObjectManager;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Invoker::Ligero::LigeroEasyConnector - GenericInterface LigeroEasyConnector Invoker backend

=head1 SYNOPSIS

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Invoker->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed params
    if ( !$Param{DebuggerObject} ) {
        return {
            Success      => 0,
            ErrorMessage => "Got no DebuggerObject!"
        };
    }

    $Self->{DebuggerObject} = $Param{DebuggerObject};

    return $Self;
}

=item PrepareRequest()

prepare the invocation of the configured remote webservice.

    my $Result = $InvokerObject->PrepareRequest(
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

=cut

sub PrepareRequest {
    my ( $Self, %Param ) = @_;

    # Caso seja necessario filtrar por webservice ID
    #my %DebuggerInfo = %{$Self->{DebuggerObject}};
    
    my %ReturnData;
    
    $ReturnData{OldTicketData} = $Param{Data}->{OldTicketData};
    
    # check Action
    if ( IsStringWithData( $Param{Data}->{Action} ) ) {
        $ReturnData{Action} = $Param{Data}->{Action};
    }

    # check request for system time
    if ( IsStringWithData( $Param{Data}->{GetSystemTime} ) && $Param{Data}->{GetSystemTime} ) {
        $ReturnData{SystemTime} = $Kernel::OM->Get('Kernel::System::Time')->SystemTime();
    }

	my %Ticket;
    my %Article;
    my @Ats; # For attachments
    my %Service;
    my %SLA;
    my %CustomerCompany;
    my %CustomerUser;

	### Get Ticket Data
    if(IsStringWithData( $Param{Data}->{TicketID} )){
		%Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
				TicketID => $Param{Data}->{TicketID}, 
				DynamicFields => 1,
				Extended => 1,
				UserID => 1
			);
        $Ticket{CustomerUser} = $Ticket{CustomerUserID};
        delete $Ticket{$_} for grep /^((?!DynamicField_)).*ID$/, keys %Ticket;
	}	

	### Get Article
    if(IsStringWithData( $Param{Data}->{ArticleID} )){
		%Article = $Kernel::OM->Get('Kernel::System::Ticket')->ArticleGet(
				ArticleID => $Param{Data}->{ArticleID}, 
				DynamicFields => 1,
				Extended => 1,
				UserID => 1
			);
        $Article{CustomerUser} = $Article{CustomerUserID};

        delete $Article{$_} for grep /^((?!DynamicField_)).*ID$/, keys %Article;

		my %Attachments = $Kernel::OM->Get('Kernel::System::Ticket')->ArticleAttachmentIndex(ArticleID => $Param{Data}->{ArticleID}, UserID => 1);
		
		for (keys %Attachments){
			my %Attachment = $Kernel::OM->Get('Kernel::System::Ticket')->ArticleAttachment(
				ArticleID => $Param{Data}->{ArticleID},
				FileID    => $_,   # as returned by ArticleAttachmentIndex
				UserID    => 1,
			);
			my %At;
			$At{Content} = encode_base64($Attachment{Content});
			$At{ContentType} = $Attachments{$_}->{ContentType};
			$At{Filename} = $Attachments{$_}->{Filename};
			
			push @Ats, \%At;
		}
	}

	#### Get Service if Any
	#if($Ticket{ServiceID}){
		#%Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
			#ServiceID => $Ticket{ServiceID},
			#UserID    => 1,
		#);
		#delete $Service{ServiceID};
		#delete $Service{ParentID};
		#delete $Service{ValidID};
		#delete $Service{CreateTime};
		#delete $Service{CreateBy};
		#delete $Service{ChangeTime};
		#delete $Service{ChangeBy};
	#}
	
	#### Get SLA if Any
	#if ($Ticket{SLAID}){
	   #%SLA = $Kernel::OM->Get('Kernel::System::SLA')->SLAGet(
		   #SLAID  => $Ticket{SLAID},
		   #UserID => 1,
	   #);
	   
		#delete $SLA{SLAID};
		#delete $SLA{ServiceIDs};
		#delete $SLA{ValidID};
		#delete $SLA{CreateBy};
		#delete $SLA{CreateTime};
		#delete $SLA{ChangeBy};
		#delete $SLA{ChangeTime};
	#}

	### Get CustomerCompany if Any
	%CustomerCompany = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyGet(
	   CustomerID => $Ticket{CustomerID},
	);

#	delete $CustomerCompany{ValidID};
	delete $CustomerCompany{Config};
	delete $CustomerCompany{CreateBy};
	delete $CustomerCompany{CreateTime};
	delete $CustomerCompany{ChangeBy};
	delete $CustomerCompany{ChangeTime};

	### Get Customer User if Any
	%CustomerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
       User => $Ticket{CustomerUserID},
	);
	delete $CustomerUser{CompanyConfig};
	delete $CustomerUser{UserID};
	delete $CustomerUser{ChangeBy};
	delete $CustomerUser{ChangeTime};
	delete $CustomerUser{Config};
	delete $CustomerUser{CreateBy};
	delete $CustomerUser{CreateTime};
	delete $CustomerUser{UserPassword};
	delete $CustomerUser{UserGoogleAuthenticatorSecretKey};
	delete $CustomerUser{$_} for grep /^CustomerCompany/, keys %CustomerUser;

     #Certificar utf8
    #for my $Obj (qw (Ticket Article Service SLA CustomerCompany CustomerUser)){
		
	#}
	#for (keys %Ticket){
        #$Ticket{$_} = encode_utf8($Ticket{$_});
    #}
    #for (keys %Article){
        #$Article{$_} = encode_utf8($Article{$_});
    #}
        
    # Verificar se este ticket é integrado (se ele possui o campo dinamico )
    $ReturnData{Ticket} 			= \%Ticket if %Ticket;
    $ReturnData{Article} 			= \%Article if %Article;
    $ReturnData{Attachment} 		= \@Ats if @Ats;
    $ReturnData{CustomerCompany} 	= \%CustomerCompany if %CustomerCompany;
    $ReturnData{CustomerUser} 		= \%CustomerUser if %CustomerUser;
    #$ReturnData{Service} 			= \%Service if %Service;
    #$ReturnData{SLA} 				= \%SLA if %SLA;

    if($Param{Data}->{PreResult} && $Param{Data}->{PreResult}->{Data}){
        $ReturnData{PreResult} = $Param{Data}->{PreResult}->{Data};
    }
    
    my $EncodeObject = $Kernel::OM->Get("Kernel::System::Encode");

    $EncodeObject->EncodeInput( \%ReturnData );

    #$Kernel::OM->Get('Kernel::System::Log')->Log( Priority => 'error', Message => "aaaaaaaaaaaa ".Dumper(%ReturnData));
        
    return {
        Success => 1,
        Data    => \%ReturnData,
    };
}

=item HandleResponse()

handle response data of the configured remote webservice.

    my $Result = $InvokerObject->HandleResponse(
        ResponseSuccess      => 1,              # success status of the remote webservice
        ResponseErrorMessage => '',             # in case of webservice error
        Data => {                               # data payload
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload after Invoker
            ...
        },
    };

=cut

sub HandleResponse {
    my ( $Self, %Param ) = @_;

    # if there was an error in the response, forward it
    if ( !$Param{ResponseSuccess} ) {
        if ( !IsStringWithData( $Param{ResponseErrorMessage} ) ) {

            return $Self->{DebuggerObject}->Error(
                Summary => 'Got response error, but no response error message!',
            );
        }

        return {
            Success      => 0,
            ErrorMessage => $Param{ResponseErrorMessage},
        };
    }

    return {
        Success => 1,
        Data    => $Param{Data},
    };
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
