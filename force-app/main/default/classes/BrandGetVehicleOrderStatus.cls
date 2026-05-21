// Returns <Brand> vehicle order status by CPF or order number. Powers Golden Flow vehicle-order-status step.
// Uses `without sharing` because Opportunity OWD is Private — the agent user needs system-context
// access to look up orders by CPF regardless of record ownership.
public without sharing class BrandGetVehicleOrderStatus {

    @InvocableMethod(
        label='<Brand> Get Vehicle Order Status'
        description='Returns the latest open <Brand> vehicle order with stage and ETA in PT/ES.'
        category='Brand Voice Agent'
    )
    public static List<Response> getOrderStatus(List<Request> requests) {
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
            String country = String.isNotBlank(r.country) ? r.country : BrandConstants.COUNTRY_BR;
            Opportunity opp = null;
            if (String.isNotBlank(r.cpf)) {
                // Try both formatted (123.456.789-00) and digits-only (12345678900) — accommodates
                // both data conventions plus the actual seeded CPF values.
                String cpfFormatted = r.cpf;
                String cpfDigits = r.cpf.replaceAll('[^0-9]', '');
                List<Opportunity> opps = [
                    SELECT Id, Name, StageName, CloseDate, Amount, AccountId, IsClosed, CreatedDate
                    FROM Opportunity
                    WHERE (Account.CPF__c = :cpfFormatted OR Account.CPF__c = :cpfDigits)
                          AND IsClosed = false
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (!opps.isEmpty()) {
                    opp = opps[0];
                }
            } else if (String.isNotBlank(r.order_number)) {
                String pattern = '%' + r.order_number + '%';
                List<Opportunity> opps = [
                    SELECT Id, Name, StageName, CloseDate, Amount, AccountId, IsClosed, CreatedDate
                    FROM Opportunity
                    WHERE Name LIKE :pattern
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (!opps.isEmpty()) {
                    opp = opps[0];
                }
            }
            if (opp == null) {
                res.success = false;
                res.output_es = 'No encontré ningún pedido abierto con esos datos.';
                res.output_pt = 'Não encontrei nenhum pedido em aberto com esses dados.';
                return res;
            }
            String stagePt = mapStagePT(opp.StageName);
            String stageEs = mapStageES(opp.StageName);
            res.success = true;
            res.opportunity_id = opp.Id;
            res.order_name = opp.Name;
            res.stage_raw = opp.StageName;
            res.stage_label_pt = stagePt;
            res.stage_label_es = stageEs;
            res.close_date = opp.CloseDate;
            res.amount = opp.Amount;
            res.output_pt = 'Encontrei seu pedido. Está na etapa de ' + stagePt +
                            ' e a previsão de entrega é de 15 a 20 dias úteis. ' +
                            'A concessionária vai entrar em contato para confirmar a data exata.';
            res.output_es = 'Encontré tu pedido. Está en la etapa de ' + stageEs +
                            ' y la previsión de entrega es de 15 a 20 días hábiles. ' +
                            'La concesionaria se va a comunicar para confirmar la fecha exacta.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    private static String mapStagePT(String stage) {
        if (String.isBlank(stage)) {
            return 'Em andamento';
        }
        String key = stage.toLowerCase();
        if (key.contains('produ')) {
            return 'Em produção';
        }
        if (key.contains('fatur')) {
            return 'Em faturamento';
        }
        if (key.contains('transp')) {
            return 'Em transporte';
        }
        if (key.contains('disponi') || key.contains('available') || key.contains('won')) {
            return 'Disponível';
        }
        // Standard Salesforce sales-process stages used as proxies for billing in the demo data.
        // Map late-funnel stages (Negotiation/Review, Proposal, Closed Won) to "Em faturamento"
        // since they represent post-deal pre-delivery state — matches the Golden Flow Case 7 dialog.
        if (key.contains('negotia') || key.contains('proposal') || key.contains('quote') || key.contains('closed won')) {
            return 'Em faturamento';
        }
        return 'Em andamento';
    }

    private static String mapStageES(String stage) {
        if (String.isBlank(stage)) {
            return 'en proceso';
        }
        String key = stage.toLowerCase();
        if (key.contains('produ')) {
            return 'producción';
        }
        if (key.contains('fatur') || key.contains('factur')) {
            return 'facturación';
        }
        if (key.contains('transp')) {
            return 'transporte';
        }
        if (key.contains('disponi') || key.contains('available') || key.contains('won')) {
            return 'disponible';
        }
        if (key.contains('negotia') || key.contains('proposal') || key.contains('quote') || key.contains('closed won')) {
            return 'facturación';
        }
        return 'en proceso';
    }

    public class Request {
        @InvocableVariable(label='CPF') public String cpf;
        @InvocableVariable(label='Order Number') public String order_number;
        @InvocableVariable(label='Country' description='AR or BR (default BR)') public String country;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String opportunity_id;
        @InvocableVariable public String order_name;
        @InvocableVariable public String stage_raw;
        @InvocableVariable public String stage_label_pt;
        @InvocableVariable public String stage_label_es;
        @InvocableVariable public Date close_date;
        @InvocableVariable public Decimal amount;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
