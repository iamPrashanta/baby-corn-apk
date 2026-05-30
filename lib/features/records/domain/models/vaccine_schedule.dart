// features/records/domain/models/vaccine_schedule.dart

class VaccineScheduleItem {
  final String name;
  final String categoryAge;
  final int recommendedDaysFromBirth;
  final String description;

  const VaccineScheduleItem({
    required this.name,
    required this.categoryAge,
    required this.recommendedDaysFromBirth,
    this.description = '',
  });
}

const List<VaccineScheduleItem> standardVaccineSchedule = [
  // Birth
  VaccineScheduleItem(name: 'BCG', categoryAge: 'Birth', recommendedDaysFromBirth: 0, description: 'Protects against Tuberculosis (TB).'),
  VaccineScheduleItem(name: 'OPV 0', categoryAge: 'Birth', recommendedDaysFromBirth: 0, description: 'Oral Polio Vaccine. Protects against poliomyelitis.'),
  VaccineScheduleItem(name: 'Hep-B 1', categoryAge: 'Birth', recommendedDaysFromBirth: 0, description: 'Protects against Hepatitis B, a serious liver disease.'),

  // 6 Weeks
  VaccineScheduleItem(name: 'DTwP 1', categoryAge: '6 Weeks', recommendedDaysFromBirth: 42, description: 'Protects against Diphtheria, Tetanus, and Pertussis (whooping cough).'),
  VaccineScheduleItem(name: 'IPV 1', categoryAge: '6 Weeks', recommendedDaysFromBirth: 42, description: 'Inactivated Polio Vaccine.'),
  VaccineScheduleItem(name: 'Hep-B 2', categoryAge: '6 Weeks', recommendedDaysFromBirth: 42, description: 'Protects against Hepatitis B.'),
  VaccineScheduleItem(name: 'Hib 1', categoryAge: '6 Weeks', recommendedDaysFromBirth: 42, description: 'Protects against Haemophilus influenzae type b (causes meningitis and pneumonia).'),
  VaccineScheduleItem(name: 'Rotavirus 1', categoryAge: '6 Weeks', recommendedDaysFromBirth: 42, description: 'Protects against severe rotavirus diarrhea.'),
  VaccineScheduleItem(name: 'PCV 1', categoryAge: '6 Weeks', recommendedDaysFromBirth: 42, description: 'Pneumococcal Conjugate Vaccine. Protects against pneumonia and meningitis.'),

  // 10 Weeks
  VaccineScheduleItem(name: 'DTwP 2', categoryAge: '10 Weeks', recommendedDaysFromBirth: 70, description: 'Protects against Diphtheria, Tetanus, and Pertussis.'),
  VaccineScheduleItem(name: 'IPV 2', categoryAge: '10 Weeks', recommendedDaysFromBirth: 70, description: 'Inactivated Polio Vaccine.'),
  VaccineScheduleItem(name: 'Hib 2', categoryAge: '10 Weeks', recommendedDaysFromBirth: 70, description: 'Protects against Haemophilus influenzae type b.'),
  VaccineScheduleItem(name: 'Rotavirus 2', categoryAge: '10 Weeks', recommendedDaysFromBirth: 70, description: 'Protects against severe rotavirus diarrhea.'),
  VaccineScheduleItem(name: 'PCV 2', categoryAge: '10 Weeks', recommendedDaysFromBirth: 70, description: 'Protects against pneumococcal disease.'),
  VaccineScheduleItem(name: 'Hep-B (10w)', categoryAge: '10 Weeks', recommendedDaysFromBirth: 70, description: 'Protects against Hepatitis B (Optional schedule variant).'),

  // 14 Weeks
  VaccineScheduleItem(name: 'DTwP 3', categoryAge: '14 Weeks', recommendedDaysFromBirth: 98, description: 'Protects against Diphtheria, Tetanus, and Pertussis.'),
  VaccineScheduleItem(name: 'IPV 3', categoryAge: '14 Weeks', recommendedDaysFromBirth: 98, description: 'Inactivated Polio Vaccine.'),
  VaccineScheduleItem(name: 'Hib 3', categoryAge: '14 Weeks', recommendedDaysFromBirth: 98, description: 'Protects against Haemophilus influenzae type b.'),
  VaccineScheduleItem(name: 'Rotavirus 3', categoryAge: '14 Weeks', recommendedDaysFromBirth: 98, description: 'Protects against severe rotavirus diarrhea.'),
  VaccineScheduleItem(name: 'PCV 3', categoryAge: '14 Weeks', recommendedDaysFromBirth: 98, description: 'Protects against pneumococcal disease.'),
  VaccineScheduleItem(name: 'Hep-B (14w)', categoryAge: '14 Weeks', recommendedDaysFromBirth: 98, description: 'Protects against Hepatitis B (Optional schedule variant).'),

  // 6 Months
  VaccineScheduleItem(name: 'OPV 1', categoryAge: '6 Months', recommendedDaysFromBirth: 180, description: 'Oral Polio Vaccine.'),
  VaccineScheduleItem(name: 'Hep-B 3', categoryAge: '6 Months', recommendedDaysFromBirth: 180, description: 'Protects against Hepatitis B.'),
  VaccineScheduleItem(name: 'Influenza 1', categoryAge: '6 Months', recommendedDaysFromBirth: 180, description: 'Protects against seasonal flu.'),

  // 7 Months
  VaccineScheduleItem(name: 'Influenza 2', categoryAge: '7 Months', recommendedDaysFromBirth: 210, description: 'Protects against seasonal flu (2nd dose).'),
  VaccineScheduleItem(name: 'Influenza Yearly', categoryAge: '7 Months', recommendedDaysFromBirth: 210, description: 'Annual flu shot.'),

  // 6–9 Months
  VaccineScheduleItem(name: 'Typhoid Conjugate Vaccine', categoryAge: '6–9 Months', recommendedDaysFromBirth: 270, description: 'Protects against typhoid fever.'),

  // 9 Months
  VaccineScheduleItem(name: 'OPV 2', categoryAge: '9 Months', recommendedDaysFromBirth: 270, description: 'Oral Polio Vaccine.'),
  VaccineScheduleItem(name: 'MMR 1', categoryAge: '9 Months', recommendedDaysFromBirth: 270, description: 'Protects against Measles, Mumps, and Rubella.'),
  VaccineScheduleItem(name: 'Meningococcal 1', categoryAge: '9 Months', recommendedDaysFromBirth: 270, description: 'Protects against meningococcal meningitis.'),
  VaccineScheduleItem(name: 'Meningococcal 2', categoryAge: '9 Months', recommendedDaysFromBirth: 270, description: 'Protects against meningococcal meningitis.'),

  // 12 Months
  VaccineScheduleItem(name: 'Hep-A 1', categoryAge: '12 Months', recommendedDaysFromBirth: 365, description: 'Protects against Hepatitis A liver disease.'),
  VaccineScheduleItem(name: 'Japanese Encephalitis 1', categoryAge: '12 Months', recommendedDaysFromBirth: 365, description: 'Protects against mosquito-borne viral brain infection.'),

  // 13 Months
  VaccineScheduleItem(name: 'Japanese Encephalitis 2', categoryAge: '13 Months', recommendedDaysFromBirth: 395, description: 'Protects against Japanese Encephalitis.'),

  // 15 Months
  VaccineScheduleItem(name: 'MMR 2', categoryAge: '15 Months', recommendedDaysFromBirth: 450, description: 'Protects against Measles, Mumps, and Rubella.'),
  VaccineScheduleItem(name: 'Varicella 1', categoryAge: '15 Months', recommendedDaysFromBirth: 450, description: 'Protects against Chickenpox.'),
  VaccineScheduleItem(name: 'PCV Booster', categoryAge: '15 Months', recommendedDaysFromBirth: 450, description: 'Pneumococcal booster.'),

  // 15–18 Months
  VaccineScheduleItem(name: 'DTwP/DTaP Booster 1', categoryAge: '15–18 Months', recommendedDaysFromBirth: 540, description: 'Booster for Diphtheria, Tetanus, and Pertussis.'),
  VaccineScheduleItem(name: 'IPV Booster 1', categoryAge: '15–18 Months', recommendedDaysFromBirth: 540, description: 'Inactivated Polio Vaccine booster.'),
  VaccineScheduleItem(name: 'Hib Booster 1', categoryAge: '15–18 Months', recommendedDaysFromBirth: 540, description: 'Haemophilus influenzae type b booster.'),

  // 18 Months
  VaccineScheduleItem(name: 'Hep-A 2', categoryAge: '18 Months', recommendedDaysFromBirth: 540, description: 'Protects against Hepatitis A.'),

  // 21 Months
  VaccineScheduleItem(name: 'Varicella 2', categoryAge: '21 Months', recommendedDaysFromBirth: 630, description: 'Protects against Chickenpox.'),

  // 2 Years
  VaccineScheduleItem(name: 'Typhoid Conjugate Booster', categoryAge: '2 Years', recommendedDaysFromBirth: 730, description: 'Booster for typhoid fever.'),

  // 4–6 Years
  VaccineScheduleItem(name: 'DTwP/DTaP Booster 2', categoryAge: '4–6 Years', recommendedDaysFromBirth: 1825, description: 'Booster for Diphtheria, Tetanus, and Pertussis.'),
  VaccineScheduleItem(name: 'IPV Booster 2', categoryAge: '4–6 Years', recommendedDaysFromBirth: 1825, description: 'Inactivated Polio Vaccine booster.'),
  VaccineScheduleItem(name: 'MMR 3', categoryAge: '4–6 Years', recommendedDaysFromBirth: 1825, description: 'Protects against Measles, Mumps, and Rubella.'),

  // 7–10 Years
  VaccineScheduleItem(name: 'Tdap / Td 1', categoryAge: '7–10 Years', recommendedDaysFromBirth: 3285, description: 'Tetanus, diphtheria, and pertussis booster.'),

  // 9–10 Years
  VaccineScheduleItem(name: 'HPV 1', categoryAge: '9–10 Years', recommendedDaysFromBirth: 3285, description: 'Protects against Human Papillomavirus.'),
  VaccineScheduleItem(name: 'HPV 2', categoryAge: '9–10 Years', recommendedDaysFromBirth: 3285, description: 'Protects against Human Papillomavirus.'),
];
