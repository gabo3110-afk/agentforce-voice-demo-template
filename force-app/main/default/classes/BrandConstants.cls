// Centralized constants for Brand Voice Agent invocable actions (country codes, languages, eligible models).
public with sharing class BrandConstants {
    public static final String COUNTRY_AR = 'AR';
    public static final String COUNTRY_BR = 'BR';
    public static final String LANG_ES = 'es-AR';
    public static final String LANG_PT = 'pt-BR';

    public static final String CHANNEL_VOICE = 'Voice';

    // <Brand>10 eligible models per program rules
    public static final Set<String> BRAND_10_ELIGIBLE_MODELS = new Set<String>{
        'ModelA', 'ModelB', 'ModelC', 'ModelD', 'ModelE'
    };

    // Default queues for case auto-assignment
    public static final String QUEUE_AR = 'TASA_AfterSales_Queue';
    public static final String QUEUE_BR = 'TDB_AfterSales_Queue';

    // Generic localized error fallback
    public static final String ERR_ES = 'Disculpá, hubo un problema procesando tu solicitud. Probá nuevamente en unos minutos.';
    public static final String ERR_PT = 'Desculpe, houve um problema ao processar sua solicitação. Tente novamente em alguns minutos.';

    public static final String NOT_FOUND_ES = 'No encontré información en el sistema con esos datos. ¿Podés verificarlos?';
    public static final String NOT_FOUND_PT = 'Não encontrei informações no sistema com esses dados. Você pode verificar?';

    public static Boolean isAR(String countryCode) {
        return COUNTRY_AR.equalsIgnoreCase(countryCode);
    }

    public static Boolean isBR(String countryCode) {
        return COUNTRY_BR.equalsIgnoreCase(countryCode);
    }
}
