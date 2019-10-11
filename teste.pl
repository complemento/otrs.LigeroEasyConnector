use Data::Dumper;
use strict;
use warnings;
use Mojo::UserAgent;
use XML::Simple;

my $ua = Mojo::UserAgent->new;

########################### LOGIN ###########################################
my $SOAP_request = <<"END_MESSAGE";
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://www.ca.com/UnicenterServicePlus/ServiceDesk">
   <soapenv:Header/>
   <soapenv:Body>
      <ser:login>
         <username>integra_gera</username>
         <password>integra_gera</password>
      </ser:login>
   </soapenv:Body>
</soapenv:Envelope>
END_MESSAGE
my $res = $ua->post('http://172.26.22.148:8080/axis/services/USD_R11_WebService' => {'SOAPAction' => '','Content-Type' => 'text/xml;charset=UTF-8'} => $SOAP_request)->result;
my $xml = XMLin($res->body);
my $auth=$xml->{"soapenv:Body"}->{loginResponse}->{loginReturn}->{content};
print "\nAuth = $auth\n";

######################################### CREATE ATTACHMENT ############################################################
$SOAP_request = <<"END_MESSAGE";
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://www.ca.com/UnicenterServicePlus/ServiceDesk">
   <soapenv:Header/>
   <soapenv:Body>
      <ser:createAttachment>
         <sid>$auth</sid>
         <repositoryHandle>doc_rep:1002</repositoryHandle>
         <objectHandle>cr:630338</objectHandle>
         <description>Teste</description>
         <fileName>teste.png</fileName>
      </ser:createAttachment>
   </soapenv:Body>
</soapenv:Envelope>
END_MESSAGE

# Ricardo, precisa criar esse arquivo no seu Mac, ou apontar para outro
my $Asset = Mojo::Asset::File->new(path => "/opt/dev/teste.png");
my $post = $ua->post("http://172.26.22.148:8080/axis/services/USD_R11_WebService" 
                => {'SOAPAction' => '','Content-Type'=>'multipart/related'} 
                => multipart => [
                     {content => $SOAP_request},
                     {file => $Asset}
                    ]
                );

print Dumper($post);

######################################### LOGOUT ############################################################
$SOAP_request = <<"END_MESSAGE";
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://www.ca.com/UnicenterServicePlus/ServiceDesk">
   <soapenv:Header/>
   <soapenv:Body>
      <ser:logout>
         <sid>$auth</sid>
      </ser:logout>
   </soapenv:Body>
</soapenv:Envelope>
END_MESSAGE
$res = $ua->post('http://172.26.22.148:8080/axis/services/USD_R11_WebService' => {'SOAPAction' => '','Content-Type' => 'text/xml;charset=UTF-8'} => $SOAP_request)->result;
# print $res->body;