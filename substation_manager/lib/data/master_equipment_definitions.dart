// lib/data/master_equipment_definitions.dart
// This map defines the master templates for all equipment types.
// Admin can define/modify these via the Master Equipment Management Screen.

final Map<String, List<Map<String, dynamic>>> masterEquipmentDefinitions = {
  'Power Transformer': [
    // Static / Specification Fields
    {
      'name': 'Voltage Ratio',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },
    {
      'name': 'Rated Power',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'MVA',
    },
    {
      'name': 'Transformer Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Core Type', 'Shell Type', 'Autotransformer'],
    },
    {
      'name': 'Cooling Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['ONAN', 'ONAF', 'OFAF', 'ODWF'],
    },
    {
      'name': 'Winding Material',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Copper', 'Aluminum'],
    },
    {
      'name': 'Vector Group',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
    },
    {
      'name': 'Impedance',
      'dataType': 'number',
      'isMandatory': true,
      'units': '%',
    },
    {
      'name': 'Tap Changer Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['On-Load (OLTC)', 'Off-Load (OFLC)'],
    },
    {
      'name': 'Number of Taps',
      'dataType': 'number',
      'isMandatory': false,
      'units': '',
    },
    {
      'name': 'Insulation Class',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
    },
    {
      'name': 'Oil Type',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Mineral Oil', 'Ester Fluid', 'Synthetic'],
    },
    {
      'name': 'Oil Volume',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Liters',
    },

    // Daily/Operational Fields (Category for filtering)
    {
      'name': 'HV Side Voltage',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'kV',
      'category': 'Daily Reading',
    },
    {
      'name': 'LV Side Voltage',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'kV',
      'category': 'Daily Reading',
    },
    {
      'name': 'HV Side Current',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'LV Side Current',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Active Power',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'MW',
      'category': 'Daily Reading',
    },
    {
      'name': 'Reactive Power',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'MVAR',
      'category': 'Daily Reading',
    },
    {
      'name': 'Winding Temperature',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
    {
      'name': 'Top Oil Temperature',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
    {
      'name': 'Oil Level (Conservator)',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Low', 'High'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Breather Silica Gel Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Blue', 'Pink', 'Other'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Cooling Fan/Pump Status',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Auto', 'Manual', 'Off', 'Fault'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Noise Level',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'High'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Oil Leakage (Visual)',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['None', 'Minor', 'Major'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Pressure Relief Device Status',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Operated'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Gas Pressure (GIS/Hermetic)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'bar',
      'category': 'Daily Reading',
    },
  ],

  'Circuit Breaker': [
    // Static Fields
    {
      'name': 'Rated Current',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'Amps',
    },
    {
      'name': 'Breaking Capacity',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'kA',
    },
    {
      'name': 'Operating Mechanism',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Spring Operated', 'Hydraulic', 'Pneumatic'],
    },
    {
      'name': 'Insulating Medium',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['SF6', 'Vacuum', 'Air Blast', 'Oil'],
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'SF6 Gas Pressure',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'bar',
      'category': 'Daily Reading',
      'conditional_on': {'Insulating Medium': 'SF6'},
    },
    {
      'name': 'Breaker Position',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Open', 'Closed'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Spring Charge Status',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Charged', 'Discharged'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Auxiliary Supply Voltage (DC)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
    {
      'name': 'Local/Remote Selector Position',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Local', 'Remote'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Trip Counter Reading',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'counts',
      'category': 'Daily Reading',
    },
  ],

  'Isolator': [
    // Static Fields
    {
      'name': 'Rated Current',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'Amps',
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Horizontal Break', 'Vertical Break', 'Pantograph'],
    },
    {
      'name': 'Number of Poles',
      'dataType': 'number',
      'isMandatory': false,
      'units': '',
    },
    {
      'name': 'Operating Mechanism',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Manual', 'Motorized'],
    },
    {
      'name': 'Earthing Switch Present',
      'dataType': 'boolean',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'Isolator Position',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Open', 'Closed'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Earthing Switch Position',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Earth', 'Open'],
      'category': 'Daily Reading',
      'conditional_on': {'Earthing Switch Present': true},
    },
    {
      'name': 'Visual Condition of Contacts',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Arc Marks', 'Overheated'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Manual Operating Effort',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Stiff'],
      'category': 'Daily Reading',
    },
  ],

  'Current Transformer (CT)': [
    // Static Fields
    {
      'name': 'Current Ratio',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'Amps',
    },
    {
      'name': 'Accuracy Class',
      'dataType': 'text',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Burden',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'VA',
    },
    {
      'name': 'Number of Cores',
      'dataType': 'number',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Insulation Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Oil Immersed', 'SF6 Gas', 'Dry Type'],
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Wound', 'Bar', 'Toroidal', 'Optical'],
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'Visual Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Cracks', 'Leakage'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Oil Level',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Low'],
      'category': 'Daily Reading',
      'conditional_on': {'Insulation Type': 'Oil Immersed'},
    },
    {
      'name': 'Earthing Connection Integrity',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Intact', 'Loose', 'Corroded'],
      'category': 'Daily Reading',
    },
  ],

  'Voltage Transformer (VT/PT)': [
    // Static Fields
    {
      'name': 'Voltage Ratio',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'V',
    },
    {
      'name': 'Accuracy Class',
      'dataType': 'text',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Burden',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'VA',
    },
    {
      'name': 'Insulation Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Oil Immersed', 'SF6 Gas', 'Dry Type'],
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Inductive VT', 'Capacitive VT (CVT)'],
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },
    {
      'name': 'Coupling Capacitance Value',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'pF',
      'conditional_on': {'Type': 'Capacitive VT (CVT)'},
    },

    // Daily/Operational Fields
    {
      'name': 'Visual Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Cracks', 'Leakage'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Oil Level',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Low'],
      'category': 'Daily Reading',
      'conditional_on': {'Insulation Type': 'Oil Immersed'},
    },
    {
      'name': 'Earthing Connection Integrity',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Intact', 'Loose', 'Corroded'],
      'category': 'Daily Reading',
    },
  ],

  'Busbar': [
    // Static Fields
    {
      'name': 'Rated Current',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'Amps',
    },
    {
      'name': 'Material',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Aluminum', 'Copper'],
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Rigid', 'Flexible'],
    },
    {
      'name': 'Configuration',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': [
        'Single Bus',
        'Double Bus',
        'Main & Transfer',
        'Breaker-and-a-Half',
      ],
    },
    {
      'name': 'Length',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'meters',
    },
    {
      'name': 'Supports Type',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Post Insulators', 'Suspension Insulators'],
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'Visual Inspection',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Corrosion', 'Dust', 'Discoloration'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Insulator Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Flash marks', 'Cracks'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Joint/Connection Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Tight', 'Loose', 'Overheated'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Temperature (Thermal Imaging)',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
  ],

  'Lightning Arrester (LA)': [
    // Static Fields
    {
      'name': 'Rated Voltage',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'kV',
    },
    {
      'name': 'Discharge Current Rating',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'kA',
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Metal Oxide Varistor (MOV)', 'Silicon Carbide (SiC)'],
    },
    {
      'name': 'Class',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Station Class', 'Intermediate Class', 'Distribution Class'],
    },

    // Daily/Operational Fields
    {
      'name': 'Visual Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Cracks', 'Punctures', 'Discoloration'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Leakage Current (if measured)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'mA',
      'category': 'Daily Reading',
    },
    {
      'name': 'LA Counter Reading',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'counts',
      'category': 'Daily Reading',
    },
    {
      'name': 'Earthing Connection Integrity',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Intact', 'Loose', 'Corroded'],
      'category': 'Daily Reading',
    },
  ],

  'Wave Trap': [
    // Static Fields
    {
      'name': 'Rated Current',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'Amps',
    },
    {
      'name': 'Inductance',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'mH',
    },
    {
      'name': 'Mounting Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Pedestal', 'Suspension'],
    },
    {
      'name': 'Resonant Frequency',
      'dataType': 'text',
      'isMandatory': false,
      'units': 'kHz',
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'Visual Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Damage to coil', 'Rust'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Insulator Condition',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Clean', 'Cracks'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Earthing Connection Integrity',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Intact', 'Loose', 'Corroded'],
      'category': 'Daily Reading',
    },
  ],

  'Shunt Reactor': [
    // Static Fields
    {
      'name': 'Rated Reactive Power',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'MVAR',
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Oil Immersed', 'Air Core', 'Gapped Core'],
    },
    {
      'name': 'Cooling Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['ONAN', 'ONAF'],
    },
    {
      'name': 'Oil Type',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Mineral Oil', 'Ester Fluid'],
      'conditional_on': {'Type': 'Oil Immersed'},
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'Top Oil Temperature',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
    {
      'name': 'Winding Hottest-Spot Temperature',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
    {
      'name': 'Oil Level (Conservator)',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Low'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Noise Level',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'High'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Oil Leakage (Visual)',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['None', 'Minor', 'Major'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Cooling Fan/Pump Status',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Auto', 'Manual', 'Off', 'Fault'],
      'category': 'Daily Reading',
    },
  ],

  'Capacitor Bank': [
    // Static Fields
    {
      'name': 'Rated Reactive Power',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'MVAR',
    },
    {
      'name': 'Number of Units/Cans',
      'dataType': 'number',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Individual Unit Capacitance',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'μF',
    },
    {
      'name': 'Discharge Resistor Present',
      'dataType': 'boolean',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Tuning Reactor Present',
      'dataType': 'boolean',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields
    {
      'name': 'Visual Condition of Cans',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Normal', 'Swelling', 'Leakage', 'Rust'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Fuse Status (Individual Cans)',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['OK', 'Blown'],
      'category': 'Daily Reading',
    },
    {
      'name': 'Cooling Fan Status',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Auto', 'Manual', 'Off'],
      'category': 'Daily Reading',
    },
  ],

  'Line': [
    // Static Fields
    {'name': 'Line Name', 'dataType': 'text', 'isMandatory': true, 'units': ''},
    {
      'name': 'Line Length',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'km',
    },
    {
      'name': 'Circuit Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Single Circuit', 'Double Circuit'],
    },
    {
      'name': 'Conductor Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': [
        'Panther',
        'Zebra',
        'Moose',
        'ACSR',
        'AAAC',
        'AAC',
        'ACAR',
        'Others',
      ],
    },
    {
      'name': 'Number of Conductors per Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': '',
    },
    {
      'name': 'Number of Earth Wires/OPGW',
      'dataType': 'number',
      'isMandatory': false,
      'units': '',
    },
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },

    // Daily/Operational Fields derived from image_58bba1.jpg and image_58bbe2.jpg
    {
      'name': 'Meter Reading (MWh)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'MWh',
      'category': 'Daily Reading',
    },
    {
      'name': 'Max Load (Amp)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Min Load (Amp)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Voltage (kV)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'kV',
      'category': 'Daily Reading',
    },
    {
      'name': 'CB Sched of Supply No.',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Supply Avail. Hrs',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'Supply Not Avail. Hrs',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'Max Load Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Min Load Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Shut Down From Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Shut Down To Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Shut Down Duration',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'Break Down From Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Break Down To Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Break Down Duration',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'HT Failure From Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'HT Failure To Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'HT Failure Duration',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'Rostering From Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Rostering To Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Rostering Duration',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'Tripping From Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Tripping To Time',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
    {
      'name': 'Tripping Duration',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Hrs',
      'category': 'Daily Reading',
    },
    {
      'name': 'Remarks',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    },
  ],

  'Battery Bank': [
    // Static Fields
    {
      'name': 'Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'V DC',
    }, // E.g., 110V, 220V
    {
      'name': 'Capacity',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'AH',
    },
    {
      'name': 'Number of Cells',
      'dataType': 'number',
      'isMandatory': true,
      'units': '',
    },
    {
      'name': 'Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Lead-Acid', 'Ni-Cd', 'Li-ion'],
    },
    {
      'name': 'Last Replacement Date',
      'dataType': 'date',
      'isMandatory': false,
      'units': '',
    },

    // Daily/Operational Fields
    {
      'name': 'Battery Voltage (Overall)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
    {
      'name': 'Cell Voltage (Min)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
    {
      'name': 'Cell Voltage (Max)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
    {
      'name': 'Battery Gravity (Min)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Sp.Gr.',
      'category': 'Daily Reading',
    },
    {
      'name': 'Battery Gravity (Max)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Sp.Gr.',
      'category': 'Daily Reading',
    },
    {
      'name': 'Float Current',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Ambient Temperature',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
  ],

  'Energy Meter': [
    // Static Fields
    {
      'name': 'Rated Voltage',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV',
    },
    {
      'name': 'Meter Type',
      'dataType': 'dropdown',
      'isMandatory': true,
      'options': ['Import', 'Export', 'Bi-directional', 'Internal Use'],
    },
    {
      'name': 'Accuracy Class',
      'dataType': 'text',
      'isMandatory': false,
      'units': '',
    },
    {'name': 'CT Ratio', 'dataType': 'text', 'isMandatory': false, 'units': ''},
    {'name': 'PT Ratio', 'dataType': 'text', 'isMandatory': false, 'units': ''},

    // Daily/Operational Fields
    {
      'name': 'Active Energy (MWh)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'MWh',
      'category': 'Daily Reading',
    },
    {
      'name': 'Reactive Energy (MVARh)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'MVARh',
      'category': 'Daily Reading',
    },
    {
      'name': 'Maximum Demand (kW)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'kW',
      'category': 'Daily Reading',
    },
    {
      'name': 'Maximum Demand (kVA)',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'kVA',
      'category': 'Daily Reading',
    },
    {
      'name': 'Power Factor',
      'dataType': 'number',
      'isMandatory': false,
      'units': '',
      'category': 'Daily Reading',
    }, // Decimal value
    {
      'name': 'Current R Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Current Y Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Current B Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Voltage R-Y Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
    {
      'name': 'Voltage Y-B Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
    {
      'name': 'Voltage B-R Phase',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'V',
      'category': 'Daily Reading',
    },
  ],
  'Auxiliary Transformer': [
    {
      'name': 'Voltage Ratio',
      'dataType': 'text',
      'isMandatory': true,
      'units': 'kV/V',
    },
    {
      'name': 'Rated Power',
      'dataType': 'number',
      'isMandatory': true,
      'units': 'kVA',
    },
    {
      'name': 'Connection Type',
      'dataType': 'dropdown',
      'isMandatory': false,
      'options': ['Delta-Star', 'Star-Star'],
    },
    {
      'name': 'Primary Current',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Secondary Current',
      'dataType': 'number',
      'isMandatory': false,
      'units': 'Amps',
      'category': 'Daily Reading',
    },
    {
      'name': 'Winding Temperature',
      'dataType': 'number',
      'isMandatory': false,
      'units': '°C',
      'category': 'Daily Reading',
    },
  ],
  // ... continue adding other equipment types with their specific static and daily reading fields ...
};
