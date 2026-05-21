// Returns warranty type, expiry, claims and <Brand>10 eligibility. Powers Golden Flow warranty step.
public with sharing class BrandGetWarrantyStatus {

    @InvocableMethod(
        label='<Brand> Get Warranty Status'
        description='Returns <Brand> warranty status including <Brand>10 eligibility and remaining days.'
        category='Brand Voice Agent'
    )
    public static List<Response> getWarrantyStatus(List<Request> requests) {
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
            List<Brand_Warranty__c> warranties = new List<Brand_Warranty__c>();
            if (String.isNotBlank(r.chassi)) {
                warranties = [
                    SELECT Id, Vehicle__c, Account__c, Warranty_Type__c, Is_Active__c, Chassi__c,
                           Coverage_Summary__c, Start_Date__c, Expiry_Date__c, Days_Remaining__c,
                           Authorized_Dealer__c, All_Services_Authorized__c, Claim_Count__c,
                           Country_Code__c, Vehicle_Model__c, Eligible_Models__c
                    FROM Brand_Warranty__c
                    WHERE Chassi__c = :r.chassi
                    ORDER BY Expiry_Date__c DESC
                    LIMIT 1
                ];
            } else if (String.isNotBlank(r.asset_id)) {
                Id assetId = (Id) r.asset_id;
                warranties = [
                    SELECT Id, Vehicle__c, Account__c, Warranty_Type__c, Is_Active__c, Chassi__c,
                           Coverage_Summary__c, Start_Date__c, Expiry_Date__c, Days_Remaining__c,
                           Authorized_Dealer__c, All_Services_Authorized__c, Claim_Count__c,
                           Country_Code__c, Vehicle_Model__c, Eligible_Models__c
                    FROM Brand_Warranty__c
                    WHERE Vehicle__c = :assetId
                    ORDER BY Expiry_Date__c DESC
                    LIMIT 1
                ];
            }
            if (warranties.isEmpty()) {
                res.success = false;
                res.output_es = BrandConstants.NOT_FOUND_ES;
                res.output_pt = BrandConstants.NOT_FOUND_PT;
                return res;
            }
            Brand_Warranty__c w = warranties[0];
            Boolean isBrand10 = isBrand10Active(w);
            res.success = true;
            res.warranty_id = w.Id;
            res.warranty_type = w.Warranty_Type__c;
            res.is_active = (w.Is_Active__c == true);
            res.is_brand10_active = isBrand10;
            res.days_remaining = w.Days_Remaining__c != null ? Integer.valueOf(w.Days_Remaining__c) : null;
            res.coverage_summary = w.Coverage_Summary__c;
            res.claim_count = w.Claim_Count__c != null ? Integer.valueOf(w.Claim_Count__c) : 0;
            res.expiry_date = w.Expiry_Date__c;
            String daysWord = res.days_remaining != null ? String.valueOf(res.days_remaining) : 'cero';
            // Coverage list — prefer the record's Coverage_Summary__c (data-driven, demo-populated),
            // fall back to the canonical <Brand>10 hardcoded list if blank.
            String coverageEs = String.isNotBlank(w.Coverage_Summary__c)
                ? w.Coverage_Summary__c
                : 'motor, transmisión, dirección, ABS, aire acondicionado y otros componentes estructurales';
            String coveragePt = String.isNotBlank(w.Coverage_Summary__c)
                ? w.Coverage_Summary__c
                : 'motor, transmissão, direção, ABS, ar-condicionado e outros componentes estruturais';
            if (isBrand10) {
                res.output_es = 'Tu <Brand>10 está activo. La cobertura incluye ' + coverageEs +
                                '. Faltan ' + daysWord + ' días para el vencimiento.';
                res.output_pt = 'Seu <Brand>10 está ativo. A cobertura inclui ' + coveragePt +
                                '. Faltam ' + daysWord + ' dias para o vencimento.';
            } else if (res.is_active) {
                res.output_es = 'Tu garantía ' + (w.Warranty_Type__c != null ? w.Warranty_Type__c : '<Brand>') +
                                ' está vigente. La cobertura incluye ' + coverageEs +
                                '. Faltan ' + daysWord + ' días para el vencimiento.';
                res.output_pt = 'Sua garantia ' + (w.Warranty_Type__c != null ? w.Warranty_Type__c : '<Brand>') +
                                ' está vigente. A cobertura inclui ' + coveragePt +
                                '. Faltam ' + daysWord + ' dias para o vencimento.';
            } else {
                res.output_es = 'Tu garantía está vencida. Te recomiendo consultar por garantía extendida.';
                res.output_pt = 'Sua garantia está vencida. Recomendo consultar a garantia estendida.';
            }
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    private static Boolean isBrand10Active(Brand_Warranty__c w) {
        if (w == null) {
            return false;
        }
        if (w.Warranty_Type__c != 'Brand10') {
            return false;
        }
        if (w.All_Services_Authorized__c != true) {
            return false;
        }
        if (w.Expiry_Date__c == null || w.Expiry_Date__c < Date.today()) {
            return false;
        }
        // Eligibility check uses substring match — "Corolla XEi G12" must match "Corolla", etc.
        // Etios is explicitly NOT eligible per the program rules.
        if (String.isNotBlank(w.Vehicle_Model__c)) {
            String modelLower = w.Vehicle_Model__c.toLowerCase();
            if (modelLower.contains('etios')) {
                return false;
            }
            Boolean matched = false;
            for (String eligible : BrandConstants.BRAND_10_ELIGIBLE_MODELS) {
                if (modelLower.contains(eligible.toLowerCase())) {
                    matched = true;
                    break;
                }
            }
            if (!matched) {
                return false;
            }
        }
        return true;
    }

    public class Request {
        @InvocableVariable(label='Chassi') public String chassi;
        @InvocableVariable(label='Asset Id') public String asset_id;
        @InvocableVariable(label='Country') public String country;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String warranty_id;
        @InvocableVariable public String warranty_type;
        @InvocableVariable public Boolean is_active;
        @InvocableVariable public Boolean is_brand10_active;
        @InvocableVariable public Integer days_remaining;
        @InvocableVariable public String coverage_summary;
        @InvocableVariable public Integer claim_count;
        @InvocableVariable public Date expiry_date;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
