########
# HBCU #
########

# Takes a CSV list of universities of the form:
# Name, Address, Website, Type
# as copied to a spreadsheet from https://sites.ed.gov/whhbcu/one-hundred-and-five-historically-black-colleges-and-universities/
# Creates a new Salesforce Institution record for each one, marking it as an HBCU

ADDRESS_REGEX = /(?<street>[^,]+), (?<city>[^,]+), (?<state>[^\d]+\w) (?<zip>[\d\-]+)/

# Educatin Institution Account type
INSTITUTION_RECORD_TYPE = '0121a0000005OPJAA2'

def sf_data(institution)
  name = institution['Name']
  address_parts = institution['Address'].match(ADDRESS_REGEX)
  street = address_parts['street']
  city = address_parts['city']
  state = address_parts['state']
  zip = address_parts['zip']
  website = institution['Website']
  type = if institution['Type'].include?('2-year')
           'Community College'
         else
           nil
         end

  return {
    Name: name,
    BillingStreet: street,
    BillingCity: city,
    BillingState: state,
    BillingPostalCode: zip,
    BillingCountry: 'United States',
    Website: website,
    Type: type,
    RecordTypeId: INSTITUTION_RECORD_TYPE,
    HBCU__c: true
  }
end

# CSV with only missing institutions included
institutions = CSV.read('../Downloads/HBCUs_cleaned.csv', headers: true)

@client = Restforce.new

institutions.each do |institution|
  id = @client.create!('Account', sf_data(institution))
  puts id
end

#######
# HSI #
#######

# Takes a CSV list of institutions of the form:
# Name, Type, State
# Type: 1 = 4-year public; 2 = 2-year public; 3 = 4-year private nonprofit; and 4 = 2-year private nonprofit.
# Derived from the Excel version of https://nces.ed.gov/programs/digest/d19/tables/dt19_312.40.asp?current=yes

@client = Restforce.new

def sf_data_hsi(institution)
  name = institution['Name']
  state = institution['State']
  
  type = if institution['Type'].to_i.even?
           'Community College'
         else
           nil
         end

  return {
    Name: name.gsub(',', ' -'),
    Type: type,
    BillingState: state,
    RecordTypeId: INSTITUTION_RECORD_TYPE,
    HSI__c: true
  }
end

# Cleaned CSV with all the existing institutions removed
hsi_data = CSV.read('../Downloads/HSIs_cleaned.csv', headers: true)

hsi_data.each do |institution|
  id = @client.create!('Account', sf_data_hsi(institution))
  puts id
end
