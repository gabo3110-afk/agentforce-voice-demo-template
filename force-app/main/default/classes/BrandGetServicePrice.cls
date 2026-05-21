// Returns the standard service price by model + km bracket. Powers Golden Flow service-price step.
public with sharing class BrandGetServicePrice {

    private static final Map<String, Map<Integer, Decimal>> PRICE_TABLE_AR = new Map<String, Map<Integer, Decimal>>{
        'Etios'   => new Map<Integer, Decimal>{ 30 => 45200,  60 => 98500,  90 => 164800, 120 => 215000 },
        'Yaris'   => new Map<Integer, Decimal>{ 30 => 52000,  60 => 108000, 90 => 178000, 120 => 235000 },
        'Corolla' => new Map<Integer, Decimal>{ 30 => 68000,  60 => 132000, 90 => 210000, 120 => 285000 },
        'SW4'     => new Map<Integer, Decimal>{ 30 => 95000,  60 => 185000, 90 => 295000, 120 => 385000 },
        'Hilux'   => new Map<Integer, Decimal>{ 30 => 88000,  60 => 172000, 90 => 275000, 120 => 355000 }
    };

    private static final Decimal AR_TO_BR_RATE = 200; // rough ARS->BRL conversion for demo

    private static final String INCLUDED_ITEMS_ES = 'aceite, filtros, revisión de frenos y suspensión';
    private static final String INCLUDED_ITEMS_PT = 'óleo, filtros, revisão de freios e suspensão';

    @InvocableMethod(
        label='<Brand> Get Service Price'
        description='Returns the standard service price for a <Brand> model at the requested km bracket.'
        category='Brand Voice Agent'
    )
    public static List<Response> getServicePrice(List<Request> requests) {
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
            if (String.isBlank(r.vehicle_model) || r.service_km == null) {
                res.success = false;
                res.output_es = 'Necesito el modelo y el kilometraje para cotizar el service.';
                res.output_pt = 'Preciso do modelo e da quilometragem para cotar o serviço.';
                return res;
            }
            String model = normalizeModel(r.vehicle_model);
            Map<Integer, Decimal> bracket = PRICE_TABLE_AR.get(model);
            if (bracket == null) {
                res.success = false;
                res.output_es = 'No tengo el precio cargado para ese modelo. ¿Querés que te derive con un asesor?';
                res.output_pt = 'Não tenho o preço cadastrado para esse modelo. Posso transferir para um consultor?';
                return res;
            }
            // Accept both bracketed (30/60/90/120) and full-km (30000/60000/90000/120000) inputs.
            Integer bracketKey = r.service_km;
            if (bracketKey >= 1000) {
                bracketKey = bracketKey / 1000;
            }
            Decimal price = bracket.get(bracketKey);
            if (price == null) {
                res.success = false;
                res.output_es = 'El service de ' + r.service_km + ' kilómetros no está en mi lista para ese modelo.';
                res.output_pt = 'O serviço de ' + r.service_km + ' quilômetros não está na minha lista para esse modelo.';
                return res;
            }
            String country = String.isNotBlank(r.country) ? r.country : BrandConstants.COUNTRY_AR;
            Decimal finalPrice = price;
            String currency1 = 'pesos';
            String currency2 = 'pesos';
            if (BrandConstants.isBR(country)) {
                finalPrice = (price / AR_TO_BR_RATE).setScale(2);
                currency1 = 'reais';
                currency2 = 'reais';
            }
            res.success = true;
            res.vehicle_model = model;
            res.service_km = r.service_km;
            res.price = finalPrice;
            res.currency_label = currency1;
            res.included_items_es = INCLUDED_ITEMS_ES;
            res.included_items_pt = INCLUDED_ITEMS_PT;
            String priceWordsEs = BrandConstants.isBR(country)
                ? VoiceFormatter.formatCurrencyPT(finalPrice)
                : VoiceFormatter.formatCurrencyES(finalPrice);
            String priceWordsPt = VoiceFormatter.formatCurrencyPT(finalPrice);
            res.output_es = 'El service de ' + r.service_km + ' mil kilómetros para tu ' + model +
                            ' tiene un valor de ' + priceWordsEs + '. Incluye ' + INCLUDED_ITEMS_ES + '.';
            res.output_pt = 'A revisão de ' + r.service_km + ' mil quilômetros para o seu ' + model +
                            ' custa ' + priceWordsPt + '. Inclui ' + INCLUDED_ITEMS_PT + '.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    private static String normalizeModel(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        String trimmed = input.trim();
        for (String key : PRICE_TABLE_AR.keySet()) {
            if (key.equalsIgnoreCase(trimmed)) {
                return key;
            }
        }
        return trimmed;
    }

    public class Request {
        @InvocableVariable(required=true label='Vehicle Model') public String vehicle_model;
        @InvocableVariable(required=true label='Service KM' description='30, 60, 90, or 120') public Integer service_km;
        @InvocableVariable(label='Country' description='AR or BR') public String country;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String vehicle_model;
        @InvocableVariable public Integer service_km;
        @InvocableVariable public Decimal price;
        @InvocableVariable public String currency_label;
        @InvocableVariable public String included_items_es;
        @InvocableVariable public String included_items_pt;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
