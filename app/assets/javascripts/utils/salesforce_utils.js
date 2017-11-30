export const extractSalesforceId = (rawSalesforceId) => {
  // We must extract the ID from a full Salesforce URL. It is 15 or 18 characters.
  // Old Salesforce URLs may look like this: https://cs54.salesforce.com/c1f1f010013YOsu?srPos=2&srKp=a0f
  let salesforceId = rawSalesforceId.replace(/\?.*/, '');
  // New Salesforce URLs look like: https://wikied.lightning.force.com/one/one.app#/sObject/a0f1a000003yDoIAAU/view
  if (salesforceId.length !== 15 && salesforceId.length !== 18) {
    salesforceId = salesforceId.replace(/\/view/, '');
    [, salesforceId] = salesforceId.match(/.*\/([\w\d]+)$/);
  }
  return salesforceId;
};
