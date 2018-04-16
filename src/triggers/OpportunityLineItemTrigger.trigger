/**
 * Created by ctuser on 4/12/2018.
 */

trigger OpportunityLineItemTrigger on OpportunityLineItem (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        OppLineItemTriggerHelper helperAfterUpdate =  new OppLineItemTriggerHelper();
        helperAfterUpdate.checkProduct(Trigger.oldMap, Trigger.new);
        System.debug(Trigger.new);
    }
}