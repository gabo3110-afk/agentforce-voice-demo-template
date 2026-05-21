// Creates a Voice-channel Case for the customer with country-aware metadata. Powers Golden Flow case-creation step.
public with sharing class BrandCreateCase {

    @InvocableMethod(
        label='<Brand> Create Case'
        description='Creates a <Brand> Case (Voice channel) for the supplied account and returns the new CaseNumber.'
        category='Brand Voice Agent'
    )
    public static List<Response> createCase(List<Request> requests) {
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
            if (String.isBlank(r.account_id) || String.isBlank(r.subject) ||
                String.isBlank(r.description) || String.isBlank(r.type) ||
                String.isBlank(r.country_code)) {
                res.success = false;
                res.output_es = 'Necesito cuenta, asunto, descripción, tipo y país para abrir el caso.';
                res.output_pt = 'Preciso de conta, assunto, descrição, tipo e país para abrir o caso.';
                return res;
            }
            Case c = new Case(
                AccountId = r.account_id,
                Subject = r.subject,
                Description = r.description,
                Type = r.type,
                Status = 'New',
                Origin = 'Voice',
                Channel_Source__c = BrandConstants.CHANNEL_VOICE,
                Country_Code__c = r.country_code
            );
            insert c;
            // Re-query to get assigned CaseNumber.
            Case inserted = [
                SELECT Id, CaseNumber
                FROM Case
                WHERE Id = :c.Id
                LIMIT 1
            ];
            res.success = true;
            res.case_id = inserted.Id;
            res.case_number = inserted.CaseNumber;
            res.output_es = 'Listo, te abrí el caso número ' + inserted.CaseNumber +
                            '. Te confirmo por mail los próximos pasos.';
            res.output_pt = 'Pronto, abri o caso número ' + inserted.CaseNumber +
                            '. Vou te enviar os próximos passos por e-mail.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(required=true label='Account Id') public String account_id;
        @InvocableVariable(required=true label='Subject') public String subject;
        @InvocableVariable(required=true label='Description') public String description;
        @InvocableVariable(required=true label='Type') public String type;
        @InvocableVariable(required=true label='Country Code' description='AR or BR') public String country_code;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String case_id;
        @InvocableVariable public String case_number;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
