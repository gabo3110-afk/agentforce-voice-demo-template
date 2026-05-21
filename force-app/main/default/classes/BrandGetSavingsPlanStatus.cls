// Looks up TPA plan status by DNI or by Group + Order. Powers Golden Flow TPA payment-status step.
public with sharing class BrandGetSavingsPlanStatus {

    @InvocableMethod(
        label='<Brand> Get TPA Status'
        description='Returns balance, pending quota and payment methods for a <Brand> Savings Plan contract.'
        category='Brand Voice Agent'
    )
    public static List<Response> getSavingsPlanStatus(List<Request> requests) {
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
            Brand_Savings_Plan__c plan = null;
            Account acc = null;
            if (String.isNotBlank(r.dni)) {
                acc = BrandCustomerLookup.findByDNI(r.dni);
                if (acc != null) {
                    List<Brand_Savings_Plan__c> plans = [
                        SELECT Id, Name, Account__c, Account__r.Name, Group_Number__c, Order_Number__c,
                               Plan_Name__c, Total_Quotas__c, Paid_Quotas__c, Pending_Quota_Amount__c,
                               Balance__c, Next_Payment_Date__c, Payment_Methods__c, Status__c, Send_To_Email__c
                        FROM Brand_Savings_Plan__c
                        WHERE Account__c = :acc.Id
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    if (!plans.isEmpty()) {
                        plan = plans[0];
                    }
                }
            } else if (String.isNotBlank(r.group_number) && String.isNotBlank(r.order_number)) {
                List<Brand_Savings_Plan__c> plans = [
                    SELECT Id, Name, Account__c, Account__r.Name, Group_Number__c, Order_Number__c,
                           Plan_Name__c, Total_Quotas__c, Paid_Quotas__c, Pending_Quota_Amount__c,
                           Balance__c, Next_Payment_Date__c, Payment_Methods__c, Status__c, Send_To_Email__c
                    FROM Brand_Savings_Plan__c
                    WHERE Group_Number__c = :r.group_number AND Order_Number__c = :r.order_number
                    LIMIT 1
                ];
                if (!plans.isEmpty()) {
                    plan = plans[0];
                }
            }
            if (plan == null) {
                res.success = false;
                res.output_es = BrandConstants.NOT_FOUND_ES;
                res.output_pt = BrandConstants.NOT_FOUND_PT;
                return res;
            }
            // Business Accounts: derive first name from Account.Name (first whitespace-separated token).
            String firstName = '';
            if (plan.Account__r != null && String.isNotBlank(plan.Account__r.Name)) {
                firstName = plan.Account__r.Name.split(' ')[0];
            }
            res.success = true;
            res.account_id = plan.Account__c;
            res.plan_id = plan.Id;
            res.plan_name = plan.Plan_Name__c;
            res.group_number = plan.Group_Number__c;
            res.order_number = plan.Order_Number__c;
            res.pending_amount = plan.Pending_Quota_Amount__c;
            res.balance = plan.Balance__c;
            res.next_payment_date = plan.Next_Payment_Date__c;
            res.payment_methods = plan.Payment_Methods__c;
            Integer monthForVoice = plan.Next_Payment_Date__c != null
                ? plan.Next_Payment_Date__c.month()
                : Date.today().month();
            String monthEs = VoiceFormatter.monthNameES(monthForVoice);
            String monthPt = VoiceFormatter.monthNamePT(monthForVoice);
            String pendingEs = plan.Pending_Quota_Amount__c != null
                ? VoiceFormatter.formatCurrencyES(plan.Pending_Quota_Amount__c) : 'cero pesos';
            String pendingPt = plan.Pending_Quota_Amount__c != null
                ? VoiceFormatter.formatCurrencyPT(plan.Pending_Quota_Amount__c) : 'zero reais';
            res.output_es = 'Te encontré en el sistema, ' + firstName +
                            '. Adeudás la cuota de ' + monthEs + ', ' + pendingEs +
                            '. Como estamos en los últimos días hábiles del mes, no aparece en home banking. ' +
                            'Podés pagarlo por Mercado Pago, Rapipago o Pago Fácil.';
            res.output_pt = 'Encontrei você no sistema, ' + firstName +
                            '. Está em aberto a parcela de ' + monthPt + ', ' + pendingPt +
                            '. Como estamos nos últimos dias úteis do mês, não aparece no home banking. ' +
                            'Você pode pagar via Mercado Pago, Rapipago ou Pago Fácil.';
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    public class Request {
        @InvocableVariable(label='DNI') public String dni;
        @InvocableVariable(label='Group Number') public String group_number;
        @InvocableVariable(label='Order Number') public String order_number;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String account_id;
        @InvocableVariable public String plan_id;
        @InvocableVariable public String plan_name;
        @InvocableVariable public String group_number;
        @InvocableVariable public String order_number;
        @InvocableVariable public Decimal pending_amount;
        @InvocableVariable public Decimal balance;
        @InvocableVariable public Date next_payment_date;
        @InvocableVariable public String payment_methods;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
