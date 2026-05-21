// Returns latest open case status by protocol number, CPF or DNI. Powers Golden Flow case-status step.
public with sharing class BrandGetCaseStatus {

    @InvocableMethod(
        label='<Brand> Get Case Status'
        description='Retrieves the most recent <Brand> case status, parts state and ETA.'
        category='Brand Voice Agent'
    )
    public static List<Response> getCaseStatus(List<Request> requests) {
        List<Response> results = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }
        for (Request r : requests) {
            results.add(processOne(r));
        }
        return results;
    }

    private static Response processOne(Request r) {
        Response res = new Response();
        try {
            Case c = null;
            if (String.isNotBlank(r.protocol_number)) {
                List<Case> cases = [
                    SELECT Id, CaseNumber, Status, Subject, Description, Protocol_Number__c,
                           Parts_Status__c, Country_Code__c, AccountId, OwnerId,
                           Owner.Name, LastModifiedDate, CreatedDate
                    FROM Case
                    WHERE Protocol_Number__c = :r.protocol_number
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];
                if (!cases.isEmpty()) {
                    c = cases[0];
                }
            } else {
                Account acc = null;
                if (String.isNotBlank(r.cpf)) {
                    acc = BrandCustomerLookup.findByCPF(r.cpf);
                } else if (String.isNotBlank(r.dni)) {
                    acc = BrandCustomerLookup.findByDNI(r.dni);
                }
                if (acc != null) {
                    List<Case> cases = [
                        SELECT Id, CaseNumber, Status, Subject, Description, Protocol_Number__c,
                               Parts_Status__c, Country_Code__c, AccountId, OwnerId,
                               Owner.Name, LastModifiedDate, CreatedDate
                        FROM Case
                        WHERE AccountId = :acc.Id AND IsClosed = false
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1
                    ];
                    if (!cases.isEmpty()) {
                        c = cases[0];
                    }
                }
            }
            if (c == null) {
                res.success = false;
                res.output_es = BrandConstants.NOT_FOUND_ES;
                res.output_pt = BrandConstants.NOT_FOUND_PT;
                return res;
            }
            res.success = true;
            res.case_id = c.Id;
            res.case_number = c.CaseNumber;
            res.status = c.Status;
            res.subject = c.Subject;
            res.protocol_number = c.Protocol_Number__c;
            res.parts_status = c.Parts_Status__c;
            res.last_modified = c.LastModifiedDate;
            res.assigned_queue = (c.Owner != null) ? c.Owner.Name : null;
            String partsLineEs = '';
            String partsLinePt = '';
            if ('Awaiting'.equals(c.Parts_Status__c) || 'InTransit'.equals(c.Parts_Status__c)) {
                partsLineEs = ' Aguardando piezas — plazo estimado de 5 a 7 días hábiles.';
                partsLinePt = ' Aguardando peças — prazo estimado de 5 a 7 dias úteis.';
            }
            res.output_es = 'Localicé tu caso. Está en curso con el equipo técnico de la concesionaria ' +
                            'y deberías tener una respuesta en hasta 48 horas hábiles.' + partsLineEs;
            res.output_pt = 'Localizei seu caso. Está em andamento com a equipe técnica da concessionária ' +
                            'e deve ter retorno em até 48 horas úteis.' + partsLinePt;
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(label='Protocol Number') public String protocol_number;
        @InvocableVariable(label='CPF') public String cpf;
        @InvocableVariable(label='DNI') public String dni;
        @InvocableVariable(label='Country') public String country;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String case_id;
        @InvocableVariable public String case_number;
        @InvocableVariable public String status;
        @InvocableVariable public String subject;
        @InvocableVariable public String protocol_number;
        @InvocableVariable public String parts_status;
        @InvocableVariable public DateTime last_modified;
        @InvocableVariable public String assigned_queue;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
