// Searches <Brand> Technical Bulletins for a description and returns trimmed content. Powers Golden Flow manual-search step.
public with sharing class BrandSearchManual {

    @InvocableMethod(
        label='<Brand> Search Manual'
        description='Searches <Brand> technical bulletins by description and returns the trimmed top match.'
        category='Brand Voice Agent'
    )
    public static List<Response> searchManual(List<Request> requests) {
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
            if (String.isBlank(r.description)) {
                res.success = false;
                res.output_es = 'Necesito una descripción para buscar en el manual.';
                res.output_pt = 'Preciso de uma descrição para buscar no manual.';
                return res;
            }
            String lang = String.isNotBlank(r.language) ? r.language.toUpperCase() : 'PT';
            Brand_Technical_Bulletin__c bulletin = null;
            // Primary: SOSL across bulletins, filtered by language
            List<List<SObject>> searchResults = [
                FIND :r.description IN ALL FIELDS
                RETURNING Brand_Technical_Bulletin__c(
                    Id, Topic__c, Content_Body__c, Source_Document__c, Vehicle_Models__c, Language__c, Tags__c
                    WHERE Language__c = :lang
                )
            ];
            if (searchResults != null && !searchResults.isEmpty()) {
                List<SObject> hits = searchResults[0];
                if (hits != null && !hits.isEmpty()) {
                    bulletin = (Brand_Technical_Bulletin__c) hits[0];
                }
            }
            // Fallback: SOQL LIKE per token across Topic / Tags / Content_Body. Tokenize the
            // description into significant words (length ≥ 4, alphabetic) and try each — the first
            // bulletin to match any token wins. This handles natural-language descriptions where the
            // full phrase doesn't match any single field.
            if (bulletin == null) {
                List<String> tokens = new List<String>();
                if (String.isNotBlank(r.description)) {
                    for (String w : r.description.toLowerCase().split('\\s+')) {
                        String clean = w.replaceAll('[^a-záéíóúñç]', '');
                        if (clean.length() >= 4) {
                            tokens.add(clean);
                        }
                    }
                }
                for (String tok : tokens) {
                    String pattern = '%' + tok + '%';
                    // Note: Content_Body__c is a LongTextArea and can't be used in WHERE clauses,
                    // so we filter on Topic__c + Tags__c + Vehicle_Models__c only.
                    List<Brand_Technical_Bulletin__c> rows = [
                        SELECT Id, Topic__c, Content_Body__c, Source_Document__c, Vehicle_Models__c, Language__c, Tags__c
                        FROM Brand_Technical_Bulletin__c
                        WHERE Language__c = :lang
                          AND (Topic__c LIKE :pattern OR Tags__c LIKE :pattern)
                        LIMIT 1
                    ];
                    if (!rows.isEmpty()) {
                        bulletin = rows[0];
                        break;
                    }
                }
            }
            if (bulletin == null) {
                res.success = false;
                res.output_es = 'No encontré información sobre eso en el manual del vehículo.';
                res.output_pt = 'Não encontrei informações sobre isso no manual do veículo.';
                return res;
            }
            String trimmed = trimToSentences(bulletin.Content_Body__c, 3);
            res.success = true;
            res.bulletin_id = bulletin.Id;
            res.topic = bulletin.Topic__c;
            res.source_document = bulletin.Source_Document__c;
            res.vehicle_models = bulletin.Vehicle_Models__c;
            res.content_body = trimmed;
            res.output_es = trimmed;
            res.output_pt = trimmed;
        } catch (Exception e) {
            res.success = false;
            res.output_es = BrandConstants.ERR_ES;
            res.output_pt = BrandConstants.ERR_PT;
            res.error_message = e.getMessage();
        }
        return res;
    }

    @TestVisible
    private static String trimToSentences(String body, Integer count) {
        if (String.isBlank(body)) {
            return '';
        }
        if (count == null || count <= 0) {
            return body;
        }
        // Split on sentence-ending punctuation while preserving content.
        List<String> sentences = body.split('(?<=[\\.!?])\\s+');
        if (sentences.isEmpty()) {
            return body;
        }
        Integer take = Math.min(count, sentences.size());
        List<String> out = new List<String>();
        for (Integer i = 0; i < take; i++) {
            out.add(sentences[i]);
        }
        return String.join(out, ' ').trim();
    }

    public class Request {
        @InvocableVariable(required=true label='Description') public String description;
        @InvocableVariable(label='Vehicle Model') public String vehicle_model;
        @InvocableVariable(required=true label='Language' description='ES or PT') public String language;
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String bulletin_id;
        @InvocableVariable public String topic;
        @InvocableVariable public String source_document;
        @InvocableVariable public String vehicle_models;
        @InvocableVariable public String content_body;
        @InvocableVariable public String output_es;
        @InvocableVariable public String output_pt;
        @InvocableVariable public String error_message;
    }
}
