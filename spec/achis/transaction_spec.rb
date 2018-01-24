require 'spec_helper'
require 'achis/transaction'

describe Achis::Transaction do

  let(:effective_date) { Date.new }

  let :valid_attributes do
    {
      id: "front_end_trace",
      transaction_type: :debit,
      amount: '12345', # expressed in cents # => USD 123.45
      effective_date: effective_date,
      first_name: 'Jonh',
      last_name: 'Doe',
      address: '',
      city: 'Los Angeles',
      state: 'CA',
      postal_code: '90210',
      telephone: '5555154324',
      email: 'abc@xyz.com',
      account_type: :saving,
      routing_number: '252574',
      account_number: '828262'
    }
  end

  subject do
    Achis::Transaction.new valid_attributes
  end

  it 'let access the attributes' do
    expect(subject.id).to               eq valid_attributes[:id]
    expect(subject.transaction_type).to eq valid_attributes[:transaction_type]
    expect(subject.amount).to           eq valid_attributes[:amount]
    expect(subject.effective_date).to   eq valid_attributes[:effective_date]
    expect(subject.first_name).to       eq valid_attributes[:first_name]
    expect(subject.last_name).to        eq valid_attributes[:last_name]
    expect(subject.address).to          eq valid_attributes[:address]
    expect(subject.city).to             eq valid_attributes[:city]
    expect(subject.state).to            eq valid_attributes[:state]
    expect(subject.postal_code).to      eq valid_attributes[:postal_code]
    expect(subject.telephone).to        eq valid_attributes[:telephone]
    expect(subject.email).to            eq valid_attributes[:email]
    expect(subject.account_type).to     eq valid_attributes[:account_type]
    expect(subject.routing_number).to   eq valid_attributes[:routing_number]
    expect(subject.account_number).to   eq valid_attributes[:account_number]
  end

  it 'raise an exception if transaction type is not :debit or :credit' do
    expect { subject.transaction_type = "Debital" }.to raise_error
  end

  it 'accept transaction type as a string' do
    subject.transaction_type = "debit"
    expect(subject.transaction_type).to eq :debit
  end

  it 'raise an exception if account type is not :saving or :checking' do
    expect { subject.account_type = "Saving" }.to raise_error
  end

  it 'accept account type as a string' do
    subject.account_type = "saving"
    expect(subject.account_type).to eq :saving
  end

  it 'strip special characters from string fields' do
    subject.first_name = "A'lgo, *d"
    expect(subject.first_name).to eq 'Algo d'
  end

  it 'let you access raw value of stripped fields' do
    subject.first_name = "A'lgo, *d"
    expect(subject.raw_first_name).to eq "A'lgo, *d"
  end

end
