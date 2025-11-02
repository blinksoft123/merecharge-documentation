import '../models/sms_bundle.dart';

const orangeSmsBundles = [
  SmsBundle(
    operator: 'Orange',
    name: 'Pack SMS Jour',
    sms: '25',
    validity: '1 jour (jusqu’à minuit)',
    price: 'Non précisé',
    activationCode: '#131*1*1#',
    network: 'Orange vers Orange',
  ),
  SmsBundle(
    operator: 'Orange',
    name: 'Pack SMS Semaine',
    sms: 'Illimités',
    validity: '7 jours',
    price: 'Non précisé',
    activationCode: '#131*1*2#',
    network: 'Orange vers Orange',
  ),
  SmsBundle(
    operator: 'Orange',
    name: 'Pack SMS Mois',
    sms: 'Illimités',
    validity: '30 jours',
    price: 'Non précisé',
    activationCode: '#131*1*3#',
    network: 'Orange vers Orange',
  ),
];

const mtnSmsBundles = [
  SmsBundle(
    operator: 'MTN',
    name: 'Unlimitext Day',
    price: '20 XAF',
    sms: 'Illimités',
    validity: '24h',
    activationCode: '*148#',
  ),
  SmsBundle(
    operator: 'MTN',
    name: 'Unlimitext Plus Day',
    price: '50 XAF',
    sms: 'Illimités',
    validity: '24h',
    activationCode: '*148#',
    bonus: '50 Mo pour WhatsApp',
  ),
  SmsBundle(
    operator: 'MTN',
    name: 'Unlimitext Plus Week',
    price: '250 XAF',
    sms: 'Illimités',
    validity: '7 jours',
    activationCode: '*148#',
    bonus: '100 Mo pour WhatsApp, Facebook, Twitter',
  ),
  SmsBundle(
    operator: 'MTN',
    name: 'Unlimitext Plus Month',
    price: '750 XAF',
    sms: 'Illimités',
    validity: '30 jours',
    activationCode: '*148#',
    bonus: '300 Mo pour WhatsApp, Facebook, Twitter',
  ),
  SmsBundle(
    operator: 'MTN',
    name: 'Yamo SMS',
    price: 'Variable (selon pack)',
    sms: 'Illimités',
    validity: '30 jours',
    activationCode: '*220#',
    bonus: 'SMS + appels selon pack',
  ),
];

const camtelSmsBundles = [
  SmsBundle(
    operator: 'Camtel',
    name: 'Blue One S',
    price: 'Non précisé',
    sms: '100',
    validity: '30 jours',
    network: 'Camtel vers Camtel',
    activationCode: '*825#',
  ),
  SmsBundle(
    operator: 'Camtel',
    name: 'Blue One M',
    price: 'Non précisé',
    sms: '200',
    validity: '30 jours',
    network: 'Camtel vers Camtel',
    activationCode: '*825#',
  ),
  SmsBundle(
    operator: 'Camtel',
    name: 'Blue One L',
    price: 'Non précisé',
    sms: '300',
    validity: '30 jours',
    network: 'Camtel vers Camtel',
    activationCode: '*825#',
  ),
];
