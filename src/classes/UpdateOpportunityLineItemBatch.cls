/**
 * Created by ctuser on 16.04.2018.
 */

global with sharing class UpdateOpportunityLineItemBatch implements Database.Batchable<sObject>, Database.Stateful {

    global Integer recordsProcessed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT ID, Product2Id, NewProduct__c FROM OpportunityLineItem WHERE NewProduct__c != null');
    }

    global void execute(Database.BatchableContext bc, List<OpportunityLineItem> scope) {
        Set<Id> oldIdSet = new Set<Id>();
        for (OpportunityLineItem oLI: scope) {
            if (oLI.Product2Id != oLi.NewProduct__c) {
                oldIdSet.add(oLI.Id);
                this.recordsProcessed += 1;
            }
        }
        OppLineItemTriggerHelper helper = new OppLineItemTriggerHelper();
        helper.updateOpportunityLineItemProduct(oldIdSet);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(recordsProcessed + ' records processed');
    }
}