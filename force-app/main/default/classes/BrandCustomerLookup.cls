// Shared resolver to find Account/Contact/Asset records by DNI, CPF, patente or VIN. Used by all customer-facing invocables.
public with sharing class BrandCustomerLookup {

    public static Account findByDNI(String dni) {
        if (String.isBlank(dni)) {
            return null;
        }
        // DNI may arrive formatted ("26.335.822") or digits-only ("26335822") depending on caller.
        // Build both forms and match either.
        String raw = dni;
        String digits = dni.replaceAll('[^0-9]', '');
        String formatted = formatDNI(digits);
        List<Account> accounts = [
            SELECT Id, Name, FirstName, LastName, DNI__c, CPF__c, Country_Code__c, Preferred_Language__c, Customer_Type__c
            FROM Account
            WHERE DNI__c = :raw OR DNI__c = :digits OR DNI__c = :formatted
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0];
    }

    public static Account findByCPF(String cpf) {
        if (String.isBlank(cpf)) {
            return null;
        }
        // CPF may arrive formatted ("987.654.321-00") or digits-only ("98765432100").
        String raw = cpf;
        String digits = cpf.replaceAll('[^0-9]', '');
        String formatted = formatCPF(digits);
        List<Account> accounts = [
            SELECT Id, Name, FirstName, LastName, DNI__c, CPF__c, Country_Code__c, Preferred_Language__c, Customer_Type__c
            FROM Account
            WHERE CPF__c = :raw OR CPF__c = :digits OR CPF__c = :formatted
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0];
    }

    private static String formatDNI(String digits) {
        // Argentine DNI is 7 or 8 digits. Format with dots as XX.XXX.XXX (or X.XXX.XXX for 7-digit).
        if (digits == null || digits.length() < 6) {
            return digits;
        }
        Integer len = digits.length();
        if (len == 8) {
            return digits.substring(0, 2) + '.' + digits.substring(2, 5) + '.' + digits.substring(5);
        }
        if (len == 7) {
            return digits.substring(0, 1) + '.' + digits.substring(1, 4) + '.' + digits.substring(4);
        }
        return digits;
    }

    private static String formatCPF(String digits) {
        // Brazilian CPF is 11 digits. Format as XXX.XXX.XXX-XX.
        if (digits == null || digits.length() != 11) {
            return digits;
        }
        return digits.substring(0, 3) + '.' + digits.substring(3, 6) + '.' + digits.substring(6, 9) + '-' + digits.substring(9);
    }

    public static Asset findByPatente(String patente) {
        if (String.isBlank(patente)) {
            return null;
        }
        List<Asset> assets = [
            SELECT Id, Name, AccountId, ContactId, VIN__c, Patente__c, Placa__c, Connected_Status__c,
                   Model_Year__c, Color__c, Generation__c, Country_Code__c,
                   Last_Service_Date__c, Last_Service_Mileage__c, Authorized_Service_Network__c,
                   Product2.Name
            FROM Asset
            WHERE Patente__c = :patente
            LIMIT 1
        ];
        return assets.isEmpty() ? null : assets[0];
    }

    public static Asset findByVIN(String vin) {
        if (String.isBlank(vin)) {
            return null;
        }
        List<Asset> assets = [
            SELECT Id, Name, AccountId, ContactId, VIN__c, Patente__c, Placa__c, Connected_Status__c,
                   Model_Year__c, Color__c, Generation__c, Country_Code__c,
                   Last_Service_Date__c, Last_Service_Mileage__c, Authorized_Service_Network__c,
                   Product2.Name
            FROM Asset
            WHERE VIN__c = :vin
            LIMIT 1
        ];
        return assets.isEmpty() ? null : assets[0];
    }

    public static Account findByAnyId(String dni, String cpf, String patente, String vin) {
        Asset a = null;
        if (String.isNotBlank(patente)) {
            a = findByPatente(patente);
        } else if (String.isNotBlank(vin)) {
            a = findByVIN(vin);
        }
        if (a != null && a.AccountId != null) {
            List<Account> accounts = [
                SELECT Id, Name, FirstName, LastName, DNI__c, CPF__c, Country_Code__c, Preferred_Language__c, Customer_Type__c
                FROM Account
                WHERE Id = :a.AccountId
                LIMIT 1
            ];
            if (!accounts.isEmpty()) {
                return accounts[0];
            }
        }
        if (String.isNotBlank(dni)) {
            return findByDNI(dni);
        }
        if (String.isNotBlank(cpf)) {
            return findByCPF(cpf);
        }
        return null;
    }
}
