/**
 * Created by ctuser on 4/12/2018.
 */

public with sharing class OppLineItemTriggerHelper {

    List<String> productIds = new List<String>();
    List<String> pricebookIds = new List<String>();
    Map<PBKey, String> newOLIMap = new Map<OppLineItemTriggerHelper.PBKey, String>();

    public void checkProduct(Map<Id, OpportunityLineItem> oldMap, List<OpportunityLineItem> newList) {
        Set<Id> oldIdSet = new Set<Id>();
        for (OpportunityLineItem oppLI : newList) {
            if (isNewProduct(oldMap.get(oppLI.Id), oppLI)) {
                oldIdSet.add(oppLI.Id);
            }
        }
        if (!oldIdSet.isEmpty()) {
            this.updateOpportunityLineItemProduct(oldIdSet);
        }
    }

    private Boolean isNewProduct(OpportunityLineItem oldOLI, OpportunityLineItem newOLI) {
        return oldOLI.NewProduct__c != newOLI.NewProduct__c
                && newOLI.NewProduct__c != null
                && newOLI.Product2Id != newOLI.NewProduct__c;
    }

    public void updateOpportunityLineItemProduct(Set<Id> oldIdSet) {
        List<String> opportunityLineItemFields = new List<String>(getFields('OpportunityLineItem'));
        List<OpportunityLineItem> opportunityLineItemList = Database.query(generateQuery(opportunityLineItemFields)).deepClone(false, false, false);
        this.fillProductAndPriceBookLists(opportunityLineItemList);
        this.fillNewOLIMap();

        for (OpportunityLineItem oLI : opportunityLineItemList) {
            oLI.PricebookEntryId = newOLIMap.get(new PBKey(oLI.NewProduct__c, oLI.PricebookEntry.Pricebook2Id));
            oLI.NewProduct__c = null;
            oLI.TotalPrice = null;
        }
            insert opportunityLineItemList;
            Database.delete(new List<Id>(oldIdSet));
    }

    private String generateQuery(List<String> fields) {
        String query = 'SELECT '
                + String.join(fields, ', ')
                + ', PriceBookEntry.PriceBook2Id FROM OpportunityLineItem WHERE Id IN :oldIdSet';
        return query;
    }

    private void fillNewOLIMap() {
        List<PricebookEntry> pBEList = [SELECT Id, Product2Id, Pricebook2Id
                                        FROM PricebookEntry
                                        WHERE Product2Id in: this.productIds
                                            AND Pricebook2Id in: this.pricebookIds
        ];
        for (PricebookEntry pBE: pBEList) {
            newOLIMap.put(new PBKey(pBE.Product2Id, pBE.Pricebook2Id), pBE.Id);
        }
    }

    private void fillProductAndPriceBookLists(List<OpportunityLineItem> opportunityLineItemList) {
        for (OpportunityLineItem o : opportunityLineItemList) {
            this.pricebookIds.add(o.PricebookEntry.Pricebook2Id);
            this.productIds.add(o.NewProduct__c);
        }
    }

    private List<String> getFields(String sObjectName) {
        List<Schema.SObjectField> sObjectFields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().values();
        List<String> fields = new List<String>();
        for (Schema.SObjectField s : sObjectFields) {
            fields.add(s.getDescribe().getName());
        }
        return fields;
    }

    private class PBKey {
        public String priceBookId;
        public String productId;

        public PBKey(String pricebookId, String productId) {
            this.priceBookId = priceBookId;
            this.productId = productId;
        }

        public Boolean equals(Object o) {
            if (o instanceof PBKey) {
                PBKey key = (PBKey) o;
                return key.priceBookId == priceBookId &&
                        key.productId == productId;
            }
            return false;
        }

        public Integer hashCode() {
            Integer result = 17;
            result = 31 * result + this.productId.hashCode();
            result = 31 * result + this.priceBookId.hashCode();
            return result;
        }
    }
}