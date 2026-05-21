// =============================================================================
// <Brand> Agentforce Voice PoC — Test Data Loader
// =============================================================================
// Loads idempotent demo data for the 8 Golden Flow customers (TASA + TDB),
// 12 Fleet Stations, 1 Technical Bulletin, plus 5 extra AR + 5 extra BR
// accounts (each with Contact + Asset).
//
// Run:    sf apex run -f scripts/apex/load-test-data.apex --target-org <brand>-af-voice
// Idempotent via upsert on external IDs (DNI, CPF, VIN, Group, Patente,
// Station_Name, Protocol_Number).
// =============================================================================

System.debug('<Brand> AF Voice — loading demo data...');

// ----------------------------------------------------------------------------
// 1. FLEET STATIONS (12) — upsert by Station_Name__c
// ----------------------------------------------------------------------------
List<Brand_Fleet_Station__c> stations = new List<Brand_Fleet_Station__c>{
    new Brand_Fleet_Station__c(Station_Name__c='Station1', Zone__c='City',
        Neighborhood__c='Zone1', Address__c='Av. Rivadavia 5500',
        Models_Available__c='SW4;Hilux DC;Corolla HV;Yaris HB TOP',
        Fuel_Types__c='Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4901-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station2', Zone__c='City',
        Neighborhood__c='Zone2', Address__c='Av. Coronel Díaz 2400',
        Models_Available__c='Yaris HB AT;Yaris HB TOP',
        Fuel_Types__c='Nafta', Has_KINTO__c=true, Phone__c='+54 11 4823-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station4', Zone__c='City',
        Neighborhood__c='Zone4', Address__c='Av. Cabildo 4500',
        Models_Available__c='Yaris HB;Hilux DC;SW4;HIACE;Corolla HV;Corolla Cross HV',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4702-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station5', Zone__c='City',
        Neighborhood__c='Zone9', Address__c='Av. Caseros 3300',
        Models_Available__c='Yaris HB;SW4;Corolla Cross HV;Corolla HV;Hilux DC',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4911-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station3', Zone__c='Region North',
        Neighborhood__c='Zone3', Address__c='Av. Maipú 1500',
        Models_Available__c='SW4;Hilux DC;Yaris HB;Corolla HV;Corolla Cross HV;HIACE',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4791-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station6', Zone__c='City',
        Neighborhood__c='Zone4', Address__c='Av. Cabildo 3700',
        Models_Available__c='Yaris HB;Yaris HB TOP;SW4;HIACE;Corolla HV',
        Fuel_Types__c='Nafta;Diesel', Has_KINTO__c=true, Phone__c='+54 11 4703-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station7', Zone__c='City',
        Neighborhood__c='Zone4', Address__c='Av. del Libertador 8000',
        Models_Available__c='Yaris HB;Yaris HB TOP;Corolla HV;Corolla Cross HV;Hilux DC',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4704-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station8', Zone__c='City',
        Neighborhood__c='Zone13', Address__c='Av. del Libertador 100',
        Models_Available__c='SW4;Hilux DC;Corolla HV;Yaris HB;Etios HB',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4314-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station9', Zone__c='Region North',
        Neighborhood__c='Zone23', Address__c='Av. del Libertador 16500',
        Models_Available__c='SW4;Hilux DC;Hilux SC;Yaris HB;Corolla HV;Corolla Cross HV',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4748-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station11', Zone__c='Region West',
        Neighborhood__c='Zone16', Address__c='Av. Francisco Beiró 5000',
        Models_Available__c='Yaris HB;Hilux DC;SW4;Corolla HV',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4501-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station12 Zone17/Zone18/Zone19/Zone20', Zone__c='Region South',
        Neighborhood__c='Zone17', Address__c='Av. Hipólito Yrigoyen 4400',
        Models_Available__c='Yaris HB;Yaris HB TOP;SW4;Hilux DC;Corolla HV;Corolla Cross HV;HIACE',
        Fuel_Types__c='Nafta;Diesel;Hybrid', Has_KINTO__c=true, Phone__c='+54 11 4241-0000'),
    new Brand_Fleet_Station__c(Station_Name__c='Station10', Zone__c='Region West',
        Neighborhood__c='Zone21', Address__c='Av. Pedro Goyena 2900',
        Models_Available__c='Yaris HB;Yaris HB TOP;Hilux DC;Hilux SC;Corolla HV;Corolla Cross HV;RAV4 PHEV',
        Fuel_Types__c='Nafta;Diesel;Hybrid;PHEV', Has_KINTO__c=true, Phone__c='+54 11 4480-0000')
};
upsert stations Station_Name__c;
System.debug('Stations upserted: ' + stations.size());

Map<String, Brand_Fleet_Station__c> stationByName = new Map<String, Brand_Fleet_Station__c>();
for (Brand_Fleet_Station__c s : stations) { stationByName.put(s.Station_Name__c, s); }

// ----------------------------------------------------------------------------
// 2. ACCOUNTS — Golden Flow customers (8) + 10 extras — upsert via DNI/CPF
// ----------------------------------------------------------------------------
List<Account> arAccounts = new List<Account>{
    new Account(Name='Demo Customer 1', Country_Code__c='AR', DNI__c='10.000.001',
        Preferred_Language__c='es-AR', Customer_Type__c='Individual', Phone='+54 11 4555-1234'),
    new Account(Name='Demo Customer 2', Country_Code__c='AR', DNI__c='10.000.002',
        Preferred_Language__c='es-AR', Customer_Type__c='Individual',
        Description='Cliente 72 años — preferir asistencia humana cuando sea posible'),
    new Account(Name='Demo Customer 3', Country_Code__c='AR', DNI__c='10.000.003',
        Preferred_Language__c='es-AR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 6', Country_Code__c='AR', DNI__c='10.000.009',
        Preferred_Language__c='es-AR', Customer_Type__c='Individual'),
    // 5 extra AR
    new Account(Name='Demo Customer 10', Country_Code__c='AR', DNI__c='10.000.005', Preferred_Language__c='es-AR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 9', Country_Code__c='AR', DNI__c='10.000.004', Preferred_Language__c='es-AR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 12', Country_Code__c='AR', DNI__c='10.000.007', Preferred_Language__c='es-AR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 11', Country_Code__c='AR', DNI__c='10.000.006', Preferred_Language__c='es-AR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 13', Country_Code__c='AR', DNI__c='10.000.008', Preferred_Language__c='es-AR', Customer_Type__c='Individual')
};
upsert arAccounts DNI__c;
System.debug('AR Accounts upserted: ' + arAccounts.size());

List<Account> brAccounts = new List<Account>{
    new Account(Name='Demo Customer 4', Country_Code__c='BR', CPF__c='100.000.001-00',
        Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 5', Country_Code__c='BR', CPF__c='110.000.002-44',
        Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 7', Country_Code__c='BR', CPF__c='100.000.003-00',
        Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 8', Country_Code__c='BR', CPF__c='100.000.004-00',
        Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    // 5 extra BR
    new Account(Name='Demo Customer 14', Country_Code__c='BR', CPF__c='100.000.005-00', Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 15', Country_Code__c='BR', CPF__c='100.000.006-00', Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 16', Country_Code__c='BR', CPF__c='100.000.007-00', Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 17', Country_Code__c='BR', CPF__c='100.000.008-00', Preferred_Language__c='pt-BR', Customer_Type__c='Individual'),
    new Account(Name='Demo Customer 18', Country_Code__c='BR', CPF__c='100.000.009-00', Preferred_Language__c='pt-BR', Customer_Type__c='Individual')
};
upsert brAccounts CPF__c;
System.debug('BR Accounts upserted: ' + brAccounts.size());

// Build lookup maps
Map<String, Account> arByDni = new Map<String, Account>();
for (Account a : arAccounts) { arByDni.put(a.DNI__c, a); }
Map<String, Account> brByCpf = new Map<String, Account>();
for (Account a : brAccounts) { brByCpf.put(a.CPF__c, a); }

// ----------------------------------------------------------------------------
// 3. CONTACTS — one per account (golden + extras)
// Use upsert with composite identity via FirstName+LastName lookup and AccountId.
// Strategy: delete existing demo Contacts for our accounts, then re-insert.
// ----------------------------------------------------------------------------
Set<Id> allAccountIds = new Set<Id>();
for (Account a : arAccounts) allAccountIds.add(a.Id);
for (Account a : brAccounts) allAccountIds.add(a.Id);

delete [SELECT Id FROM Contact WHERE AccountId IN :allAccountIds];

List<Contact> contacts = new List<Contact>();
// Golden AR
contacts.add(new Contact(FirstName='Pablo', LastName='Ferreira', AccountId=arByDni.get('10.000.001').Id, DNI__c='10.000.001', Country_Code__c='AR', Preferred_Language__c='es-AR', Phone='+54 11 4555-1234', Email='pablo.ferreira@example.com.ar'));
contacts.add(new Contact(FirstName='Ronaldo', LastName='Casotest', AccountId=arByDni.get('10.000.002').Id, DNI__c='10.000.002', Country_Code__c='AR', Preferred_Language__c='es-AR', Phone='+54 11 4901-9876', MailingCity='Zone1'));
contacts.add(new Contact(FirstName='Demo Customer 3', LastName='Galante', AccountId=arByDni.get('10.000.003').Id, DNI__c='10.000.003', Country_Code__c='AR', Preferred_Language__c='es-AR', Email='demo-customer@example.com'));
contacts.add(new Contact(FirstName='María Juan', LastName='López Ricchi', AccountId=arByDni.get('10.000.009').Id, DNI__c='10.000.009', Country_Code__c='AR', Preferred_Language__c='es-AR'));
// Golden BR
contacts.add(new Contact(FirstName='Valdemir', LastName='Silva', AccountId=brByCpf.get('100.000.001-00').Id, CPF__c='100.000.001-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='João', LastName='Santos', AccountId=brByCpf.get('110.000.002-44').Id, CPF__c='110.000.002-44', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='Patricia', LastName='Almeida', AccountId=brByCpf.get('100.000.003-00').Id, CPF__c='100.000.003-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='Carlos', LastName='Pereira', AccountId=brByCpf.get('100.000.004-00').Id, CPF__c='100.000.004-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
// Extras AR
contacts.add(new Contact(FirstName='Lucía', LastName='Fernández', AccountId=arByDni.get('10.000.005').Id, DNI__c='10.000.005', Country_Code__c='AR', Preferred_Language__c='es-AR'));
contacts.add(new Contact(FirstName='Diego', LastName='Martínez', AccountId=arByDni.get('10.000.004').Id, DNI__c='10.000.004', Country_Code__c='AR', Preferred_Language__c='es-AR'));
contacts.add(new Contact(FirstName='Sofía', LastName='Romero', AccountId=arByDni.get('10.000.007').Id, DNI__c='10.000.007', Country_Code__c='AR', Preferred_Language__c='es-AR'));
contacts.add(new Contact(FirstName='Matías', LastName='García', AccountId=arByDni.get('10.000.006').Id, DNI__c='10.000.006', Country_Code__c='AR', Preferred_Language__c='es-AR'));
contacts.add(new Contact(FirstName='Camila', LastName='Suárez', AccountId=arByDni.get('10.000.008').Id, DNI__c='10.000.008', Country_Code__c='AR', Preferred_Language__c='es-AR'));
// Extras BR
contacts.add(new Contact(FirstName='Ana', LastName='Oliveira', AccountId=brByCpf.get('100.000.005-00').Id, CPF__c='100.000.005-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='Pedro', LastName='Costa', AccountId=brByCpf.get('100.000.006-00').Id, CPF__c='100.000.006-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='Mariana', LastName='Souza', AccountId=brByCpf.get('100.000.007-00').Id, CPF__c='100.000.007-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='Lucas', LastName='Rodrigues', AccountId=brByCpf.get('100.000.008-00').Id, CPF__c='100.000.008-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
contacts.add(new Contact(FirstName='Beatriz', LastName='Lima', AccountId=brByCpf.get('100.000.009-00').Id, CPF__c='100.000.009-00', Country_Code__c='BR', Preferred_Language__c='pt-BR'));
insert contacts;
System.debug('Contacts inserted: ' + contacts.size());

// ----------------------------------------------------------------------------
// 4. ASSETS — vehicles for golden + extras
// Upsert by VIN__c (external ID).
// ----------------------------------------------------------------------------
List<Asset> assets = new List<Asset>{
    // Golden — Demo Customer 1 (Etios)
    new Asset(Name='<Brand> ModelA — Demo Customer 1', AccountId=arByDni.get('10.000.001').Id,
        VIN__c='VIN0000000000001', Patente__c='AA 100 AA', Country_Code__c='AR',
        Model_Year__c=2018, Color__c='Gris Plata',
        Last_Service_Date__c=Date.today().addDays(-90), Last_Service_Mileage__c=85000,
        Authorized_Service_Network__c=true, Status='Purchased'),
    // Golden — Demo Customer 4 (Corolla XEi G12 BR)
    new Asset(Name='<Brand> ModelC 2019 — Demo Customer 4', AccountId=brByCpf.get('100.000.001-00').Id,
        VIN__c='CHASSI000000003', Placa__c='BR1A001', Country_Code__c='BR',
        Model_Year__c=2020, Color__c='Branco Pérola', Generation__c='G12',
        Last_Service_Mileage__c=30000, Authorized_Service_Network__c=true, Status='Purchased'),
    // Golden — María Juan (SW4 connected)
    new Asset(Name='<Brand> ModelD 2022 — López Ricchi', AccountId=arByDni.get('10.000.009').Id,
        VIN__c='VIN0000000000002', Patente__c='AA 200 BB', Country_Code__c='AR',
        Model_Year__c=2022, Color__c='Negro Mica', Connected_Status__c=true,
        Authorized_Service_Network__c=true, Status='Purchased'),
    // Golden — Demo Customer 8 (Corolla 2024 BR)
    new Asset(Name='<Brand> ModelC 2024 — Demo Customer 8', AccountId=brByCpf.get('100.000.004-00').Id,
        VIN__c='VIN0000000000014', Placa__c='BR1A002', Country_Code__c='BR',
        Model_Year__c=2024, Color__c='Prata',
        Authorized_Service_Network__c=true, Status='Purchased'),
    // Extras AR (5)
    new Asset(Name='<Brand> ModelB — Demo Customer 10', AccountId=arByDni.get('10.000.005').Id, VIN__c='VIN0000000000008', Patente__c='AA 700 GG', Country_Code__c='AR', Model_Year__c=2021, Color__c='Rojo Imperial', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelE — Demo Customer 9', AccountId=arByDni.get('10.000.004').Id, VIN__c='VIN0000000000006', Patente__c='AA 500 EE', Country_Code__c='AR', Model_Year__c=2020, Color__c='Blanco Polar', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelC — Demo Customer 12', AccountId=arByDni.get('10.000.007').Id, VIN__c='VIN0000000000005', Patente__c='AA 400 DD', Country_Code__c='AR', Model_Year__c=2023, Color__c='Gris Cemento', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelC — Demo Customer 11', AccountId=arByDni.get('10.000.006').Id, VIN__c='VIN0000000000004', Patente__c='AA 300 CC', Country_Code__c='AR', Model_Year__c=2022, Color__c='Azul Cobalto', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelF — Demo Customer 13', AccountId=arByDni.get('10.000.008').Id, VIN__c='VIN00000000000075', Patente__c='AA 600 FF', Country_Code__c='AR', Model_Year__c=2024, Color__c='Negro Atitude', Authorized_Service_Network__c=true, Status='Purchased'),
    // Extras BR (5)
    new Asset(Name='<Brand> ModelB — Demo Customer 14', AccountId=brByCpf.get('100.000.005-00').Id, VIN__c='VIN0000000000013', Placa__c='BR1A003', Country_Code__c='BR', Model_Year__c=2022, Color__c='Vermelho Granada', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelE — Demo Customer 15', AccountId=brByCpf.get('100.000.006-00').Id, VIN__c='VIN0000000000010', Placa__c='BR1A004', Country_Code__c='BR', Model_Year__c=2023, Color__c='Cinza Granito', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelC — Demo Customer 16', AccountId=brByCpf.get('100.000.007-00').Id, VIN__c='VIN0000000000009', Placa__c='BR1A005', Country_Code__c='BR', Model_Year__c=2024, Color__c='Prata Lunar', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelD — Demo Customer 17', AccountId=brByCpf.get('100.000.008-00').Id, VIN__c='VIN0000000000012', Placa__c='BR1A006', Country_Code__c='BR', Model_Year__c=2021, Color__c='Branco Pérola', Authorized_Service_Network__c=true, Status='Purchased'),
    new Asset(Name='<Brand> ModelE SW4 — Demo Customer 18', AccountId=brByCpf.get('100.000.009-00').Id, VIN__c='VIN0000000000011', Placa__c='BR1A007', Country_Code__c='BR', Model_Year__c=2022, Color__c='Preto Attitude', Authorized_Service_Network__c=true, Status='Purchased')
};
upsert assets VIN__c;
System.debug('Assets upserted: ' + assets.size());

Map<String, Asset> assetByVin = new Map<String, Asset>();
for (Asset a : assets) { assetByVin.put(a.VIN__c, a); }

// ----------------------------------------------------------------------------
// 5. SERVICE APPOINTMENTS for Demo Customer 1's Etios — 5 prior services
// (delete and recreate to stay idempotent)
// ----------------------------------------------------------------------------
Id pabloAssetId = assetByVin.get('VIN0000000000001').Id;
delete [SELECT Id FROM ServiceAppointment WHERE Subject LIKE 'Service %k Etios — Station12%'];

List<ServiceAppointment> svcs = new List<ServiceAppointment>();
List<Integer> mileages = new List<Integer>{30000, 45000, 60000, 75000, 85000};
for (Integer i = 0; i < mileages.size(); i++) {
    Integer mi = mileages[i];
    Datetime sched = Datetime.now().addDays(-(365 * (5 - i)));
    svcs.add(new ServiceAppointment(
        Subject='Service ' + mi + 'k Etios — Station12',
        Description='BRAND-DEMO-SVC mileage=' + mi + ' VIN=VIN0000000000001',
        SchedStartTime=sched,
        SchedEndTime=sched.addHours(2),
        Status='Completed',
        ParentRecordId=pabloAssetId
    ));
}
insert svcs;
System.debug('ServiceAppointments inserted: ' + svcs.size());

// ----------------------------------------------------------------------------
// 6. BRAND WARRANTY — Demo Customer 4 (<Brand> 10)
// ----------------------------------------------------------------------------
Id valdemirAssetId = assetByVin.get('CHASSI000000003').Id;
delete [SELECT Id FROM Brand_Warranty__c WHERE Chassi__c='CHASSI000000003'];
Brand_Warranty__c war = new Brand_Warranty__c(
    Vehicle__c=valdemirAssetId,
    Account__c=brByCpf.get('100.000.001-00').Id,
    Warranty_Type__c='Brand10',
    Is_Active__c=true,
    Chassi__c='CHASSI000000003',
    Coverage_Summary__c='Motor, transmissão, sistema de direção, ABS, ar-condicionado, reservatório de fluido, unidade de controle',
    Eligible_Models__c='["Corolla XEi G12","Corolla Cross HV","Yaris G2","Hilux GR Sport"]',
    Start_Date__c=Date.newInstance(2020, 1, 15),
    Expiry_Date__c=Date.newInstance(2030, 1, 15),
    All_Services_Authorized__c=true,
    Claim_Count__c=0,
    Vehicle_Model__c='Corolla XEi G12',
    Authorized_Dealer__c='DealerCity1',
    Country_Code__c='BR'
);
insert war;
System.debug('Warranty inserted for Valdemir.');

// ----------------------------------------------------------------------------
// 7. TPA PLAN — Demo Customer 3
// ----------------------------------------------------------------------------
Date eom = Date.today().toStartOfMonth().addMonths(1).addDays(-1);
Brand_Savings_Plan__c[] tpas = new List<Brand_Savings_Plan__c>{
    new Brand_Savings_Plan__c(
        Account__c=arByDni.get('10.000.003').Id,
        Group_Number__c='777',
        Order_Number__c='42',
        Plan_Name__c='<Brand> ModelB',
        Total_Quotas__c=84,
        Paid_Quotas__c=72,
        Pending_Quota_Amount__c=185000,
        Balance__c=2220000,
        Next_Payment_Date__c=eom,
        Send_To_Email__c='demo-customer@example.com',
        Status__c='Active',
        Payment_Methods__c='MercadoPago;Rapipago;PagoFacil'
    )
};
upsert tpas Group_Number__c;
System.debug('TPA Plans upserted.');

// ----------------------------------------------------------------------------
// 8. CONNECTED VEHICLE — María Juan SW4
// ----------------------------------------------------------------------------
Id swId = assetByVin.get('VIN0000000000002').Id;
delete [SELECT Id FROM Brand_Connected_Vehicle__c WHERE Patente__c='AA 200 BB'];
Brand_Connected_Vehicle__c cv = new Brand_Connected_Vehicle__c(
    Vehicle__c=swId,
    Patente__c='AA 200 BB',
    Current_Titular_Name__c='PRIOR DEMO TITULAR',
    Current_Titular_DNI__c='10.000.099',
    Connected_Status__c=true,
    Pending_Titular_Change__c=false,
    Activation_Date__c=Date.today().addDays(-400)
);
insert cv;
System.debug('Connected vehicle inserted.');

// ----------------------------------------------------------------------------
// 9. CASES — Golden Flow protocol cases for Demo Customer 5 (BR)
// ----------------------------------------------------------------------------
Id joaoAcct = brByCpf.get('110.000.002-44').Id;
delete [SELECT Id FROM Case WHERE Protocol_Number__c IN ('797-3','797-4')];
List<Case> cases = new List<Case>{
    new Case(
        AccountId=joaoAcct,
        Protocol_Number__c='797-3',
        Status='Working',
        Subject='Consulta técnica em andamento',
        Type='AfterSales',
        Country_Code__c='BR',
        Description='Em andamento com equipe técnica da concessionária — ETA 48 horas úteis',
        Channel_Source__c='Voice'
    ),
    new Case(
        AccountId=joaoAcct,
        Protocol_Number__c='797-4',
        Status='Working',
        Subject='Aguardando peças',
        Type='AfterSales',
        Country_Code__c='BR',
        Parts_Status__c='Awaiting',
        Description='Aguardando peças — ETA 5 a 7 dias úteis',
        Channel_Source__c='Voice'
    )
};
insert cases;
System.debug('Cases inserted: ' + cases.size());

// ----------------------------------------------------------------------------
// 10. OPPORTUNITY — Demo Customer 7 vehicle order
// ----------------------------------------------------------------------------
Id patriciaAcct = brByCpf.get('100.000.003-00').Id;
delete [SELECT Id FROM Opportunity WHERE AccountId=:patriciaAcct AND Name LIKE '<Brand> ModelC 2026%'];
Opportunity opp = new Opportunity(
    Name='<Brand> ModelC 2026 — Patricia',
    AccountId=patriciaAcct,
    StageName='Negotiation/Review',
    CloseDate=Date.today().addDays(18),
    Amount=185000,
    Description='Faturamento — entrega prevista em 18 dias'
);
insert opp;
System.debug('Opportunity inserted.');

// ----------------------------------------------------------------------------
// 11. TECHNICAL BULLETIN — VSC Button (PT for Demo Customer 8)
// ----------------------------------------------------------------------------
delete [SELECT Id FROM Brand_Technical_Bulletin__c WHERE Topic__c LIKE 'Botão VSC%'];
Brand_Technical_Bulletin__c tb = new Brand_Technical_Bulletin__c(
    Topic__c='Botão VSC — controle de estabilidade',
    Vehicle_Models__c='Corolla',
    Language__c='PT',
    Country_Code__c='BR',
    Content_Body__c='O botão cinza com símbolo de carro com setas é o VSC (Vehicle Stability Control). Pressionar brevemente desativa o controle de tração — útil em areia ou barro. Pressionar por mais de 3 segundos desativa o VSC completo. Mantenha ativo em condições normais de estrada.',
    Source_Document__c='Manual Corolla 2024, p. 142',
    Tags__c='VSC,estabilidade,Corolla,botão cinza,traction control'
);
insert tb;
System.debug('Technical bulletin inserted.');

System.debug('==============================================');
System.debug('<Brand> AF Voice — demo data load COMPLETE.');
System.debug('AR Accounts: ' + arAccounts.size() + ' | BR Accounts: ' + brAccounts.size());
System.debug('Stations: ' + stations.size() + ' | Assets: ' + assets.size() + ' | Contacts: ' + contacts.size());
System.debug('==============================================');
