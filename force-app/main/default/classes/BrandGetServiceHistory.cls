// Returns up to 5 most recent ServiceAppointments for a vehicle. Powers Golden Flow service-history step.
public with sharing class BrandGetServiceHistory {

    @InvocableMethod(
        label='<Brand> Get Service History'
        description='Returns up to 5 most recent service appointments for a <Brand> vehicle.'
        category='Brand Voice Agent'
    )
    public static List<Response> getServiceHistory(List<Request> requests) {
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
        res.entries = new List<HistoryEntry>();
        try {
            Asset asset = null;
            if (String.isNotBlank(r.patente)) {
                asset = BrandCustomerLookup.findByPatente(r.patente);
            } else if (String.isNotBlank(r.vin)) {
                asset = BrandCustomerLookup.findByVIN(r.vin);
            }
            String accountId = r.account_id;
            if (asset != null && String.isBlank(accountId)) {
                accountId = asset.AccountId;
            }
            if (asset == null && String.isBlank(accountId)) {
                res.success = false;
                res.output_es = BrandConstants.NOT_FOUND_ES;
                res.output_pt = BrandConstants.NOT_FOUND_PT;
                return res;
            }
            Boolean isOfficial = (asset != null && asset.Authorized_Service_Network__c == true);
            String dealerName = '';
            // ServiceAppointment is standard FSL object. Query top 5 by SchedStartTime.
            List<ServiceAppointment> appts = new List<ServiceAppointment>();
            if (asset != null) {
                // Use AccessLevel.USER_MODE with try/catch — graceful when individual fields
                // aren't FLS-readable for the agent runtime user.
                try {
                    appts = [
                        SELECT Id, SchedStartTime, AppointmentNumber, WorkType.Name, Subject, Status
                        FROM ServiceAppointment
                        WHERE ParentRecordId = :asset.Id
                        ORDER BY SchedStartTime DESC
                        LIMIT 5
                    ];
                } catch (Exception qe) {
                    // Fallback: minimal projection that any read-permitted user can see.
                    appts = [
                        SELECT Id, SchedStartTime, Subject, Status
                        FROM ServiceAppointment
                        WHERE ParentRecordId = :asset.Id
                        ORDER BY SchedStartTime DESC
                        LIMIT 5
                    ];
                }
            }
            for (ServiceAppointment sa : appts) {
                HistoryEntry h = new HistoryEntry();
                h.appointment_id = sa.Id;
                h.scheduled_date = sa.SchedStartTime;
                h.service_type = sa.WorkType != null ? sa.WorkType.Name : sa.Subject;
                // Subject convention: "Service 30000k Etios — Zento" → dealer is the part after " — ".
                String inferredDealer = '';
                if (String.isNotBlank(sa.Subject) && sa.Subject.contains(' — ')) {
                    inferredDealer = sa.Subject.substringAfter(' — ').trim();
                }
                h.dealer = inferredDealer;
                h.is_official = isOfficial;
                if (String.isBlank(dealerName)) {
                    dealerName = h.dealer;
                }
                res.entries.add(h);
            }
            res.success = true;
            res.is_official = isOfficial;
            res.last_dealer = dealerName;
            String dealerEs = String.isNotBlank(dealerName) ? dealerName : 'concesionaria oficial <Brand>';
            String dealerPt = String.isNotBlank(dealerName) ? dealerName : 'concessionária oficial <Brand>';
            if (isOfficial) {
                res.output_es = 'Todos los services fueron realizados en concesionarias oficiales <Brand>, en ' +
                                dealerEs + '. Tu vehículo está al día.';
                res.output_pt = 'Todos os serviços foram realizados em concessionárias oficiais <Brand>, em ' +
                                dealerPt + '. Seu veículo está em dia.';
            } else {
                res.output_es = 'No tenemos registro de services en la red oficial <Brand> para este vehículo.';
                res.output_pt = 'Não temos registro de serviços na rede oficial <Brand> para este veículo.';
            }
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(label='Patente') public String patente;
        @InvocableVariable(label='VIN') public String vin;
        @InvocableVariable(label='Account Id') public String account_id;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public List<HistoryEntry> entries;
        @InvocableVariable public Boolean is_official;
        @InvocableVariable public String last_dealer;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }

    public class HistoryEntry {
        @InvocableVariable public String appointment_id;
        @InvocableVariable public DateTime scheduled_date;
        @InvocableVariable public String service_type;
        @InvocableVariable public String dealer;
        @InvocableVariable public Boolean is_official;
    }
}
