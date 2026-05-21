// Voice-friendly formatter helpers. Converts numbers, dates and phones to readable Spanish/Portuguese strings.
public with sharing class VoiceFormatter {

    private static final List<String> ES_UNITS = new List<String>{
        'cero','uno','dos','tres','cuatro','cinco','seis','siete','ocho','nueve',
        'diez','once','doce','trece','catorce','quince','dieciséis','diecisiete','dieciocho','diecinueve',
        'veinte','veintiuno','veintidós','veintitrés','veinticuatro','veinticinco','veintiséis','veintisiete','veintiocho','veintinueve'
    };

    private static final Map<Integer, String> ES_TENS = new Map<Integer, String>{
        30 => 'treinta', 40 => 'cuarenta', 50 => 'cincuenta',
        60 => 'sesenta', 70 => 'setenta', 80 => 'ochenta', 90 => 'noventa'
    };

    private static final Map<Integer, String> ES_HUNDREDS = new Map<Integer, String>{
        100 => 'cien', 200 => 'doscientos', 300 => 'trescientos', 400 => 'cuatrocientos',
        500 => 'quinientos', 600 => 'seiscientos', 700 => 'setecientos',
        800 => 'ochocientos', 900 => 'novecientos'
    };

    private static final List<String> PT_UNITS = new List<String>{
        'zero','um','dois','três','quatro','cinco','seis','sete','oito','nove',
        'dez','onze','doze','treze','catorze','quinze','dezesseis','dezessete','dezoito','dezenove'
    };

    private static final Map<Integer, String> PT_TENS = new Map<Integer, String>{
        20 => 'vinte', 30 => 'trinta', 40 => 'quarenta', 50 => 'cinquenta',
        60 => 'sessenta', 70 => 'setenta', 80 => 'oitenta', 90 => 'noventa'
    };

    private static final Map<Integer, String> PT_HUNDREDS = new Map<Integer, String>{
        100 => 'cem', 200 => 'duzentos', 300 => 'trezentos', 400 => 'quatrocentos',
        500 => 'quinhentos', 600 => 'seiscentos', 700 => 'setecentos',
        800 => 'oitocentos', 900 => 'novecentos'
    };

    private static final List<String> ES_MONTHS = new List<String>{
        '','enero','febrero','marzo','abril','mayo','junio',
        'julio','agosto','septiembre','octubre','noviembre','diciembre'
    };

    private static final List<String> PT_MONTHS = new List<String>{
        '','janeiro','fevereiro','março','abril','maio','junho',
        'julho','agosto','setembro','outubro','novembro','dezembro'
    };

    public static String formatCurrencyES(Decimal amount) {
        if (amount == null) {
            return 'cero pesos';
        }
        Long whole = amount.longValue();
        String words = numberToWordsES(whole);
        return words + ' pesos';
    }

    public static String formatCurrencyPT(Decimal amount) {
        if (amount == null) {
            return 'zero reais';
        }
        Long whole = amount.longValue();
        String words = numberToWordsPT(whole);
        return words + ' reais';
    }

    public static String formatDateES(Date d) {
        if (d == null) {
            return '';
        }
        return d.day() + ' de ' + ES_MONTHS[d.month()] + ' de ' + d.year();
    }

    public static String formatDatePT(Date d) {
        if (d == null) {
            return '';
        }
        return d.day() + ' de ' + PT_MONTHS[d.month()] + ' de ' + d.year();
    }

    public static String formatPhoneES(String phone) {
        if (String.isBlank(phone)) {
            return '';
        }
        // Strip non-digits, then space-separate digits for clear voice playback.
        String digits = phone.replaceAll('[^0-9]', '');
        List<String> parts = new List<String>();
        for (Integer i = 0; i < digits.length(); i++) {
            parts.add(String.valueOf(digits.substring(i, i + 1)));
        }
        return String.join(parts, ' ');
    }

    public static String monthNameES(Integer month) {
        if (month == null || month < 1 || month > 12) {
            return '';
        }
        return ES_MONTHS[month];
    }

    public static String monthNamePT(Integer month) {
        if (month == null || month < 1 || month > 12) {
            return '';
        }
        return PT_MONTHS[month];
    }

    @TestVisible
    private static String numberToWordsES(Long n) {
        if (n == 0) {
            return 'cero';
        }
        if (n < 0) {
            return 'menos ' + numberToWordsES(-n);
        }
        List<String> parts = new List<String>();
        Long millions = n / 1000000;
        Long remainder = Math.mod(n, 1000000);
        Long thousands = remainder / 1000;
        Long units = Math.mod(remainder, 1000);
        if (millions > 0) {
            if (millions == 1) {
                parts.add('un millón');
            } else {
                parts.add(under1000ES(millions.intValue()) + ' millones');
            }
        }
        if (thousands > 0) {
            if (thousands == 1) {
                parts.add('mil');
            } else {
                parts.add(under1000ES(thousands.intValue()) + ' mil');
            }
        }
        if (units > 0) {
            parts.add(under1000ES(units.intValue()));
        }
        return String.join(parts, ' ');
    }

    private static String under1000ES(Integer n) {
        if (n < 30) {
            return ES_UNITS[n];
        }
        if (n < 100) {
            Integer tens = (n / 10) * 10;
            Integer rest = Math.mod(n, 10);
            if (rest == 0) {
                return ES_TENS.get(tens);
            }
            return ES_TENS.get(tens) + ' y ' + ES_UNITS[rest];
        }
        if (n == 100) {
            return 'cien';
        }
        Integer hundreds = (n / 100) * 100;
        Integer rest = Math.mod(n, 100);
        String prefix = ES_HUNDREDS.get(hundreds);
        if (hundreds == 100 && rest > 0) {
            prefix = 'ciento';
        }
        if (rest == 0) {
            return prefix;
        }
        return prefix + ' ' + under1000ES(rest);
    }

    @TestVisible
    private static String numberToWordsPT(Long n) {
        if (n == 0) {
            return 'zero';
        }
        if (n < 0) {
            return 'menos ' + numberToWordsPT(-n);
        }
        List<String> parts = new List<String>();
        Long millions = n / 1000000;
        Long remainder = Math.mod(n, 1000000);
        Long thousands = remainder / 1000;
        Long units = Math.mod(remainder, 1000);
        if (millions > 0) {
            if (millions == 1) {
                parts.add('um milhão');
            } else {
                parts.add(under1000PT(millions.intValue()) + ' milhões');
            }
        }
        if (thousands > 0) {
            if (thousands == 1) {
                parts.add('mil');
            } else {
                parts.add(under1000PT(thousands.intValue()) + ' mil');
            }
        }
        if (units > 0) {
            parts.add(under1000PT(units.intValue()));
        }
        return String.join(parts, ' e ');
    }

    private static String under1000PT(Integer n) {
        if (n < 20) {
            return PT_UNITS[n];
        }
        if (n < 100) {
            Integer tens = (n / 10) * 10;
            Integer rest = Math.mod(n, 10);
            if (rest == 0) {
                return PT_TENS.get(tens);
            }
            return PT_TENS.get(tens) + ' e ' + PT_UNITS[rest];
        }
        if (n == 100) {
            return 'cem';
        }
        Integer hundreds = (n / 100) * 100;
        Integer rest = Math.mod(n, 100);
        String prefix = PT_HUNDREDS.get(hundreds);
        if (hundreds == 100 && rest > 0) {
            prefix = 'cento';
        }
        if (rest == 0) {
            return prefix;
        }
        return prefix + ' e ' + under1000PT(rest);
    }
}
