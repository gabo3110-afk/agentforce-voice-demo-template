// Sends a TPA payment-instruction email + logs an account Task. Powers Golden Flow TPA self-service hand-off.
public with sharing class BrandSendVoucherEmail {

    @InvocableMethod(
        label='<Brand> Send TPA Cupon'
        description='Creates an EmailMessage and Task delivering the <Brand> Savings Plan self-service instructions.'
        category='Brand Voice Agent'
    )
    public static List<Response> sendVoucherEmail(List<Request> requests) {
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
            if (String.isBlank(r.account_id) || String.isBlank(r.email)) {
                res.success = false;
                res.output_es = 'Necesito el mail al que enviar el instructivo.';
                res.output_pt = 'Preciso do email para enviar o instrutivo.';
                return res;
            }
            // Lookup most recent TPA plan for the account (used as RelatedTo)
            List<Brand_Savings_Plan__c> plans = [
                SELECT Id, Plan_Name__c
                FROM Brand_Savings_Plan__c
                WHERE Account__c = :r.account_id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            Id relatedId = plans.isEmpty() ? null : plans[0].Id;

            EmailMessage em = new EmailMessage(
                ToAddress = r.email,
                Subject = '<Brand> Savings Plan — Instructivo de cupón',
                HtmlBody = buildHtmlBody(),
                TextBody = buildTextBody(),
                Status = '3', // Sent
                MessageDate = DateTime.now(),
                RelatedToId = relatedId
            );
            insert em;

            Task t = new Task(
                Subject = 'Cupón TPA enviado',
                Status = 'Completed',
                Priority = 'Normal',
                WhatId = r.account_id,
                Description = 'Voice agent sent self-service instructions to ' + r.email,
                ActivityDate = Date.today()
            );
            insert t;

            res.success = true;
            res.email_message_id = em.Id;
            res.task_id = t.Id;
            res.output_es = 'Listo, te envío el instructivo a ' + r.email + ' con todos los pasos.';
            res.output_pt = 'Pronto, envio o instrutivo para ' + r.email + ' com todos os passos.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    private static String buildHtmlBody() {
        return '<p>Hola,</p>' +
               '<p>Compartimos el instructivo para gestionar el pago de tu cuota del Plan de Ahorro <Brand>.</p>' +
               '<ol>' +
               '<li>Ingresá al portal de autogestión <Brand> Savings Plan.</li>' +
               '<li>Seleccioná tu grupo y orden.</li>' +
               '<li>Elegí el medio de pago: Mercado Pago, Rapipago o Pago Fácil.</li>' +
               '<li>Descargá el cupón y aboná antes del vencimiento.</li>' +
               '</ol>' +
               '<p>Saludos,<br/><Brand> Argentina</p>';
    }

    private static String buildTextBody() {
        return 'Instructivo <Brand> Savings Plan\n' +
               '1. Ingresá al portal de autogestión.\n' +
               '2. Seleccioná tu grupo y orden.\n' +
               '3. Elegí el medio de pago: Mercado Pago, Rapipago o Pago Fácil.\n' +
               '4. Descargá el cupón y aboná antes del vencimiento.\n';
    }

    public class Request {
        @InvocableVariable(required=true label='Account Id') public String account_id;
        @InvocableVariable(required=true label='Email') public String email;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String email_message_id;
        @InvocableVariable public String task_id;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
