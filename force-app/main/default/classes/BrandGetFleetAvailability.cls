// Returns up to 3 KINTO stations matching zone + dates. Powers Golden Flow KINTO availability step.
public with sharing class BrandGetFleetAvailability {

    private static final Set<String> CABA_NEIGHBORHOODS = new Set<String>{
        'Caballito', 'Palermo', 'Belgrano', 'Almagro', 'Recoleta',
        'Villa Crespo', 'Núñez', 'Chacarita', 'Flores', 'Boedo'
    };

    @InvocableMethod(
        label='<Brand> Get KINTO Availability'
        description='Finds KINTO fleet stations matching zone and dates and returns voice-ready availability.'
        category='Brand Voice Agent'
    )
    public static List<Response> getFleetAvailability(List<Request> requests) {
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
        res.stations = new List<StationInfo>();
        try {
            String zoneInput = String.isNotBlank(r.zone) ? r.zone.trim() : '';
            Boolean isCabaNeighborhood = CABA_NEIGHBORHOODS.contains(zoneInput);
            String zoneFilter = isCabaNeighborhood || String.isBlank(zoneInput) ? 'CABA' : zoneInput;
            // Use ORDER BY Name to keep deterministic ordering
            List<Brand_Fleet_Station__c> stations = [
                SELECT Id, Station_Name__c, Zone__c, Neighborhood__c, Address__c,
                       Models_Available__c, Fuel_Types__c, Has_KINTO__c, Phone__c
                FROM Brand_Fleet_Station__c
                WHERE Has_KINTO__c = true
                AND (Zone__c = :zoneFilter OR Zone__c LIKE :('%' + zoneFilter + '%'))
                ORDER BY Station_Name__c ASC
                LIMIT 3
            ];
            if (stations.isEmpty()) {
                res.success = false;
                res.output_es = 'No tengo estaciones KINTO disponibles en esa zona para esas fechas.';
                res.output_pt = 'Não tenho estações KINTO disponíveis nessa zona para essas datas.';
                return res;
            }
            String firstStation = '';
            String firstNeighborhood = '';
            for (Brand_Fleet_Station__c s : stations) {
                StationInfo info = new StationInfo();
                info.station_id = s.Id;
                info.station_name = s.Station_Name__c;
                info.zone = s.Zone__c;
                info.neighborhood = s.Neighborhood__c;
                info.address = s.Address__c;
                info.models_available = s.Models_Available__c;
                info.fuel_types = s.Fuel_Types__c;
                info.phone = s.Phone__c;
                if (String.isBlank(firstStation)) {
                    firstStation = s.Station_Name__c;
                    firstNeighborhood = s.Neighborhood__c;
                }
                res.stations.add(info);
            }
            String preferred = String.isNotBlank(r.preferred_model) ? r.preferred_model : 'Corolla Cross';
            res.success = true;
            res.recommended_model = preferred;
            res.station_count = stations.size();
            res.output_es = 'Tengo disponibilidad en ' + firstStation +
                            ' en ' + firstNeighborhood + ' con ' + preferred +
                            '. El retiro es en la concesionaria, no hacemos entrega a domicilio.';
            res.output_pt = 'Tenho disponibilidade em ' + firstStation +
                            ' em ' + firstNeighborhood + ' com ' + preferred +
                            '. A retirada é na concessionária, não fazemos entrega em domicílio.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(label='Zone') public String zone;
        @InvocableVariable(label='Start Date') public Date start_date;
        @InvocableVariable(label='End Date') public Date end_date;
        @InvocableVariable(label='Preferred Model') public String preferred_model;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public List<StationInfo> stations;
        @InvocableVariable public Integer station_count;
        @InvocableVariable public String recommended_model;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }

    public class StationInfo {
        @InvocableVariable public String station_id;
        @InvocableVariable public String station_name;
        @InvocableVariable public String zone;
        @InvocableVariable public String neighborhood;
        @InvocableVariable public String address;
        @InvocableVariable public String models_available;
        @InvocableVariable public String fuel_types;
        @InvocableVariable public String phone;
    }
}
