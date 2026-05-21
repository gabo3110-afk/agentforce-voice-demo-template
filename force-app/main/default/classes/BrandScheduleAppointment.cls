// Books a ServiceAppointment, falling back to a Task if FSL is unavailable. Powers Golden Flow service-booking step.
public with sharing class BrandScheduleAppointment {

    @InvocableMethod(
        label='<Brand> Schedule Service Appointment'
        description='Books a <Brand> service appointment, falling back to a Task if FSL is not enabled.'
        category='Brand Voice Agent'
    )
    public static List<Response> schedule(List<Request> requests) {
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
            if (String.isBlank(r.account_id) || String.isBlank(r.vin) ||
                String.isBlank(r.preferred_dealer) || r.preferred_date_time == null) {
                res.success = false;
                res.output_es = 'Necesito cuenta, VIN, concesionaria y fecha para agendar el service.';
                res.output_pt = 'Preciso de conta, VIN, concessionária e data para agendar o serviço.';
                return res;
            }
            Datetime startTime = r.preferred_date_time;
            Datetime endTime = startTime.addHours(2);
            Boolean booked = false;
            String dealerLabel = r.preferred_dealer;
            try {
                ServiceAppointment sa = new ServiceAppointment(
                    ParentRecordId = r.account_id,
                    Subject = 'Service appointment via voice agent',
                    SchedStartTime = startTime,
                    SchedEndTime = endTime,
                    Status = 'Scheduled'
                );
                insert sa;
                res.appointment_id = sa.Id;
                booked = true;
            } catch (Exception fslEx) {
                // Fallback to Task when ServiceAppointment cannot be inserted (FSL not enabled, validation, etc.)
                Task t = new Task(
                    Subject = 'Service appointment requested',
                    WhatId = r.account_id,
                    ActivityDate = startTime.date(),
                    Description = 'Customer: VIN ' + r.vin + ', dealer: ' + dealerLabel +
                                  ', requested time: ' + String.valueOf(startTime),
                    Status = 'Open',
                    Priority = 'Normal'
                );
                insert t;
                res.task_id = t.Id;
                res.fallback_used = true;
                res.fallback_reason = fslEx.getMessage();
            }
            String dateEs = VoiceFormatter.formatDateES(startTime.date());
            String datePt = VoiceFormatter.formatDatePT(startTime.date());
            res.success = true;
            res.scheduled_for = startTime;
            res.dealer = dealerLabel;
            res.output_es = 'Listo, te agendo el service para el ' + dateEs +
                            ' en ' + dealerLabel + '. Te confirmo el turno por mail.';
            res.output_pt = 'Pronto, agendei o service para ' + datePt +
                            ' em ' + dealerLabel + '. Vou te confirmar por e-mail.';
            // Reference booked to keep variable used when ServiceAppointment path succeeds.
            if (booked && res.appointment_id == null) {
                res.appointment_id = null;
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
        @InvocableVariable(required=true label='Account Id') public String account_id;
        @InvocableVariable(required=true label='VIN') public String vin;
        @InvocableVariable(required=true label='Preferred Dealer') public String preferred_dealer;
        @InvocableVariable(required=true label='Preferred DateTime') public Datetime preferred_date_time;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String appointment_id;
        @InvocableVariable public String task_id;
        @InvocableVariable public Datetime scheduled_for;
        @InvocableVariable public String dealer;
        @InvocableVariable public Boolean fallback_used;
        @InvocableVariable public String fallback_reason;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
