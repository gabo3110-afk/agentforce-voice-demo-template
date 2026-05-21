// Returns the registered titular for a connected <Brand> vehicle by patente. Powers Golden Flow connected-services step.
public with sharing class BrandGetConnectedTitular {

    @InvocableMethod(
        label='<Brand> Get Connected Titular'
        description='Returns the current titular of a <Brand> Connected vehicle and instructions for transfer.'
        category='Brand Voice Agent'
    )
    public static List<Response> getConnectedTitular(List<Request> requests) {
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
            if (String.isBlank(r.patente)) {
                res.success = false;
                res.output_es = 'Necesito la patente para verificar la unidad conectada.';
                res.output_pt = 'Preciso da placa para verificar o veículo conectado.';
                return res;
            }
            List<Brand_Connected_Vehicle__c> vehicles = [
                SELECT Id, Vehicle__c, Patente__c, Connected_Status__c,
                       Current_Titular_Name__c, Current_Titular_DNI__c,
                       Linked_Email__c, Pending_Titular_Change__c, Activation_Date__c
                FROM Brand_Connected_Vehicle__c
                WHERE Patente__c = :r.patente
                LIMIT 1
            ];
            if (vehicles.isEmpty()) {
                res.success = false;
                res.output_es = 'No encontré ese vehículo en el sistema. ¿Me confirmás la patente?';
                res.output_pt = 'Não encontrei esse veículo no sistema. Pode confirmar a placa?';
                return res;
            }
            Brand_Connected_Vehicle__c v = vehicles[0];
            String titularName = String.isNotBlank(v.Current_Titular_Name__c) ? v.Current_Titular_Name__c : '';
            res.success = true;
            res.connected_vehicle_id = v.Id;
            res.titular_name = titularName;
            res.connected_status = (v.Connected_Status__c == true);
            res.linked_email = v.Linked_Email__c;
            res.output_es = 'La unidad está registrada a nombre de ' + titularName +
                            '. Para hacer el cambio, enviá un mail a connected-support@<brand>.example.com ' +
                            'con el título automotor digital y tu licencia de conducir.';
            res.output_pt = 'O veículo está registrado em nome de ' + titularName +
                            '. Para fazer a transferência, envie um email para suporteConectados@<brand>.com.br ' +
                            'com o documento do veículo digital e sua carteira de motorista.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(required=true label='Patente') public String patente;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String connected_vehicle_id;
        @InvocableVariable public String titular_name;
        @InvocableVariable public Boolean connected_status;
        @InvocableVariable public String linked_email;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
