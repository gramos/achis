New Provider Specs
===================

* Credentials:

 protocol, host, username, password, merchant_id (if  exists)

* Return file naming convention.

* Returns path.

* Returns file format and specs with a example.

* Payment file naming convention.

* Payments file path.

* Payments file format and specs with a fixture file based on:

```ruby
def transaction_debit
  Achis::Transaction.new(
    id:               "FD00AFA8A0F7",
    transaction_type: :debit,
    amount:           '16',
    effective_date:   Date.new(2013, 03, 26),
    first_name:       'marge',
    last_name:        'baker',
    address:          '101 2nd st',
    city:             'wellsville',
    state:            'KS',
    postal_code:      '66092',
    telephone:        '5858232966',
    account_type:     'checking',
    routing_number:   '103100195',
    account_number:   '3423423253234'
  )
end

def transaction_credit
  Achis::Transaction.new(
    id:               "665E0601D848",
    transaction_type: :credit,
    amount:           '20.50',
    effective_date:   Date.new(2013, 03, 26),
    first_name:       'James,,,',
    last_name:        'Good, man',
    address:          '10 Maple Dr, APT 123',
    city:             'Boiling Springs,',
    state:            'PA,',
    postal_code:      '17007',
    telephone:        '6155320889',
    email:            'abc@xyz.com',
    account_type:     'saving',
    routing_number:   '124003116',
    account_number:   '192312313'
  )
end
```
