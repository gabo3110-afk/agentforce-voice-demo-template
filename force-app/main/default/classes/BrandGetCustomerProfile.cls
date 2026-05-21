// Resolve Account+Contact+primary Asset by patente, VIN, DNI or CPF. Powers Golden Flow customer-identification step.
public with sharing class BrandGetCustomerProfile {

    @InvocableMethod(
        label='<Brand> Get Customer Profile'
        description='Resolves the <Brand> customer using patente, VIN, DNI or CPF and returns voice-ready greeting.'
        category='Brand Voice Agent'
    )
    public static List<Response> getCustomerProfile(List<Request> requests) {
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
            Asset asset = null;
            if (String.isNotBlank(r.patente)) {
                asset = BrandCustomerLookup.findByPatente(r.patente);
            } else if (String.isNotBlank(r.vin)) {
                asset = BrandCustomerLookup.findByVIN(r.vin);
            }
            Account acc = BrandCustomerLookup.findByAnyId(r.dni, r.cpf, r.patente, r.vin);
            if (acc == null && asset == null) {
                res.success = false;
                res.output_es = BrandConstants.NOT_FOUND_ES;
                res.output_pt = BrandConstants.NOT_FOUND_PT;
                return res;
            }
            if (asset == null && acc != null) {
                List<Asset> assets = [
                    SELECT Id, Name, AccountId, VIN__c, Patente__c, Placa__c, Model_Year__c,
                           Color__c, Country_Code__c, Authorized_Service_Network__c, Product2.Name
                    FROM Asset
                    WHERE AccountId = :acc.Id
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (!assets.isEmpty()) {
                    asset = assets[0];
                }
            }
            Integer openCases = 0;
            if (acc != null) {
                List<AggregateResult> ar = [
                    SELECT COUNT(Id) c
                    FROM Case
                    WHERE AccountId = :acc.Id AND IsClosed = false
                ];
                if (!ar.isEmpty()) {
                    openCases = (Integer) ar[0].get('c');
                }
            }
            res.success = true;
            res.account_id = acc?.Id;
            // Business Accounts don't have FirstName — derive from Account.Name (first token).
            String accountFirstName = (acc != null && String.isNotBlank(acc.Name)) ? acc.Name.split(' ')[0] : '';
            res.first_name = accountFirstName;
            res.country_code = acc?.Country_Code__c;
            res.asset_id = asset?.Id;
            res.patente = asset?.Patente__c != null ? asset.Patente__c : asset?.Placa__c;
            // Prefer Product2.Name; fall back to extracting model from Asset.Name like
            // "<Brand> Etios XLS AT — Pablo Ferreira" → "Etios XLS AT".
            String vModel = null;
            if (asset?.Product2 != null && String.isNotBlank(asset.Product2.Name)) {
                vModel = asset.Product2.Name;
            } else if (asset != null && String.isNotBlank(asset.Name)) {
                String n = asset.Name;
                if (n.contains(' — ')) { n = n.substringBefore(' — '); }
                if (n.startsWithIgnoreCase('<Brand> ')) { n = n.substring(7); }
                vModel = n;
            }
            res.vehicle_model = vModel;
            res.model_year = asset?.Model_Year__c != null ? String.valueOf(asset.Model_Year__c) : null;
            res.color = asset?.Color__c;
            res.open_case_count = openCases;
            String fname = accountFirstName;
            String model = res.vehicle_model != null ? res.vehicle_model : '';
            String yr = res.model_year != null ? res.model_year : '';
            String col = String.isNotBlank(res.color) ? res.color : '';
            String pat = String.isNotBlank(res.patente) ? res.patente : '';
            res.output_es = 'Hola ' + fname + ', confirmo tu <Brand> ' + model + ' ' + yr +
                            ' color ' + col + ', patente ' + pat + ', todo en orden. Tenés ' +
                            openCases + ' casos abiertos.';
            res.output_pt = 'Olá ' + fname + ', confirmo seu <Brand> ' + model + ' ' + yr +
                            ' cor ' + col + ', placa ' + pat + ', tudo em ordem. Você tem ' +
                            openCases + ' casos abertos.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(label='Patente' description='AR licence plate')
        public String patente;
        @InvocableVariable(label='VIN' description='Vehicle Identification Number')
        public String vin;
        @InvocableVariable(label='DNI' description='Argentine DNI')
        public String dni;
        @InvocableVariable(label='CPF' description='Brazilian CPF')
        public String cpf;
        @InvocableVariable(label='Country Code' description='AR or BR')
        public String country_code;
    }

    public class Response {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Account Id') public String account_id;
        @InvocableVariable(label='First Name') public String first_name;
        @InvocableVariable(label='Country Code') public String country_code;
        @InvocableVariable(label='Asset Id') public String asset_id;
        @InvocableVariable(label='Patente') public String patente;
        @InvocableVariable(label='Vehicle Model') public String vehicle_model;
        @InvocableVariable(label='Model Year') public String model_year;
        @InvocableVariable(label='Color') public String color;
        @InvocableVariable(label='Open Case Count') public Integer open_case_count;
        @InvocableVariable(label='Output ES') public String output_es;
        @InvocableVariable(label='Output PT') public String output_pt;
        @InvocableVariable(label='Error Message') public String error_message;
    }
}
