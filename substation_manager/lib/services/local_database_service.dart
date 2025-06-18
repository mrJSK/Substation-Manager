// lib/services/local_database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle; // For loading assets

import 'package:substation_manager/models/area.dart';
import 'package:substation_manager/models/substation.dart';
import 'package:substation_manager/models/bay.dart'; // Ensure this import is correct: should be bay.dart
import 'package:substation_manager/models/equipment.dart';
import 'package:substation_manager/models/master_equipment_template.dart';
import 'package:substation_manager/models/daily_reading.dart';
import 'package:substation_manager/models/task.dart';
import 'package:substation_manager/models/user_profile.dart';
import 'package:substation_manager/models/electrical_connection.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'substation_manager.db';
  static const int _databaseVersion = 3;

  static final StreamController<List<Area>> _areasStreamController =
      StreamController<List<Area>>.broadcast();
  static final StreamController<List<Substation>> _substationsStreamController =
      StreamController<List<Substation>>.broadcast();
  static final StreamController<List<Bay>> _baysStreamController =
      StreamController<List<Bay>>.broadcast();
  static final StreamController<List<Equipment>> _equipmentStreamController =
      StreamController<List<Equipment>>.broadcast();
  static final StreamController<List<MasterEquipmentTemplate>>
  _masterEquipmentTemplatesStreamController =
      StreamController<List<MasterEquipmentTemplate>>.broadcast();
  static final StreamController<List<DailyReading>>
  _dailyReadingsStreamController =
      StreamController<List<DailyReading>>.broadcast();
  static final StreamController<List<Task>> _tasksStreamController =
      StreamController<List<Task>>.broadcast();
  static final StreamController<List<StateModel>> _statesStreamController =
      StreamController<List<StateModel>>.broadcast();
  static final StreamController<List<CityModel>> _citiesStreamController =
      StreamController<List<CityModel>>.broadcast();
  static final StreamController<List<ElectricalConnection>>
  _connectionsStreamController =
      StreamController<List<ElectricalConnection>>.broadcast();

  static const String _areasTable = 'areas';
  static const String _substationsTable = 'substations';
  static const String _baysTable = 'bays';
  static const String _equipmentTable = 'equipment';
  static const String _masterEquipmentTemplatesTable =
      'master_equipment_templates';
  static const String _dailyReadingsTable = 'daily_readings';
  static const String _tasksTable = 'tasks';
  static const String _statesTable = 'core_state';
  static const String _citiesTable = 'core_city';
  static const String _userProfilesTable = 'user_profiles';
  static const String _connectionsTable = 'electrical_connections';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> initializeDatabase() async {
    await database;
    _updateAreaStream();
    _updateSubstationStream();
    _updateBayStream();
    _updateEquipmentStream();
    _updateMasterEquipmentTemplateStream();
    _updateDailyReadingStream();
    _updateTaskStream();
    _updateStateStream();
    _updateCityStream();
    _updateConnectionStream();
    print('Local database initialized successfully.');
  }

  Future<void> _onCreate(Database db, int version) async {
    print('DEBUG: _onCreate called for DB version $version.');
    await db.execute('''
      CREATE TABLE $_areasTable(
        id TEXT PRIMARY KEY,
        name TEXT,
        areaPurpose TEXT,
        state TEXT,
        cities TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_substationsTable(
        id TEXT PRIMARY KEY,
        name TEXT,
        areaId TEXT,
        voltageLevels TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        cityId REAL,
        stateId REAL,
        type TEXT,
        yearOfCommissioning INTEGER,
        totalConnectedCapacityMVA REAL,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_baysTable(
        id TEXT PRIMARY KEY,
        substationId TEXT,
        name TEXT,
        type TEXT,
        voltageLevel TEXT,
        isIncoming INTEGER,
        sequenceNumber INTEGER,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_equipmentTable(
        id TEXT PRIMARY KEY,
        substationId TEXT,
        bayId TEXT,
        equipmentType TEXT,
        name TEXT,
        yearOfManufacturing INTEGER,
        yearOfCommissioning INTEGER,
        make TEXT,
        serialNumber TEXT,
        ratedVoltage TEXT,
        ratedCurrent TEXT,
        status TEXT,
        phaseConfiguration TEXT,
        positionX REAL,
        positionY REAL,
        details TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_masterEquipmentTemplatesTable(
        id TEXT PRIMARY KEY,
        equipmentType TEXT,
        customFields TEXT,
        associatedRelays TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_dailyReadingsTable(
        id TEXT PRIMARY KEY,
        equipmentId TEXT,
        substationId TEXT,
        readingForDate TEXT,
        readingTimeOfDay TEXT,
        readings TEXT,
        recordedByUserId TEXT,
        recordDateTime TEXT,
        status TEXT,
        notes TEXT,
        photoPath TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tasksTable(
        id TEXT PRIMARY KEY,
        assignedToUserId TEXT,
        assignedToUserName TEXT,
        assignedByUserId TEXT,
        assignedByUserName TEXT,
        substationId TEXT,
        substationName TEXT,
        targetEquipmentIds TEXT,
        targetReadingFields TEXT,
        frequency TEXT,
        dueDate TEXT,
        status TEXT,
        createdAt TEXT,
        completionDate TEXT,
        reviewNotes TEXT,
        associatedReadingIds TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_statesTable(
        id REAL PRIMARY KEY,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_citiesTable(
        id REAL PRIMARY KEY,
        name TEXT,
        state_id REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_userProfilesTable(
        id TEXT PRIMARY KEY,
        email TEXT,
        displayName TEXT,
        mobile TEXT,
        role TEXT,
        status TEXT,
        assignedSubstationIds TEXT,
        assignedAreaIds TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_connectionsTable(
        id TEXT PRIMARY KEY,
        substationId TEXT,
        bayId TEXT,
        fromEquipmentId TEXT,
        toEquipmentId TEXT,
        connectionType TEXT,
        points TEXT
      )
    ''');
    print('Database created with version $version.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('DEBUG: _onUpgrade called from version $oldVersion to $newVersion.');
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $_equipmentTable ADD COLUMN phaseConfiguration TEXT DEFAULT \'Single Unit\'',
      );
      await db.execute(
        'ALTER TABLE $_equipmentTable ADD COLUMN positionX REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE $_equipmentTable ADD COLUMN positionY REAL DEFAULT 0.0',
      );

      await db.execute('''
        CREATE TABLE $_connectionsTable(
          id TEXT PRIMARY KEY,
          substationId TEXT,
          bayId TEXT,
          fromEquipmentId TEXT,
          toEquipmentId TEXT,
          connectionType TEXT,
          points TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      print(
        'DEBUG: Upgrading to v3: Modifying $_substationsTable and $_areasTable.',
      );
      // 1. Substations table schema change:
      // Create temp table, copy, drop old, create new, insert from temp, drop temp
      await db.execute(
        'CREATE TEMPORARY TABLE substations_old AS SELECT id, name, areaId, voltageLevels, latitude, longitude, address, cityId, stateId, type, yearOfCommissioning, totalConnectedCapacityMVA, notes FROM $_substationsTable',
      );
      await db.execute('DROP TABLE $_substationsTable');
      await db.execute('''
        CREATE TABLE $_substationsTable(
          id TEXT PRIMARY KEY,
          name TEXT,
          areaId TEXT,
          voltageLevels TEXT,
          latitude REAL,
          longitude REAL,
          address TEXT,
          cityId REAL,
          stateId REAL,
          type TEXT,
          yearOfCommissioning INTEGER,
          totalConnectedCapacityMVA REAL,
          notes TEXT
        )
      ''');
      await db.execute(
        'INSERT INTO $_substationsTable (id, name, areaId, voltageLevels, latitude, longitude, address, cityId, stateId, type, yearOfCommissioning, totalConnectedCapacityMVA, notes) SELECT id, name, areaId, voltageLevels, latitude, longitude, address, cityId, stateId, type, yearOfCommissioning, totalConnectedCapacityMVA, notes FROM substations_old',
      );
      await db.execute('DROP TABLE substations_old');

      // 2. Areas table schema change (remove description, add areaPurpose)
      await db.execute(
        'CREATE TEMPORARY TABLE areas_old AS SELECT id, name, state, cities FROM $_areasTable',
      );
      await db.execute('DROP TABLE $_areasTable');
      await db.execute('''
        CREATE TABLE $_areasTable(
          id TEXT PRIMARY KEY,
          name TEXT,
          areaPurpose TEXT DEFAULT "Transmission",
          state TEXT,
          cities TEXT
        )
      ''');
      await db.execute(
        'INSERT INTO $_areasTable (id, name, areaPurpose, state, cities) SELECT id, name, "Transmission", state, cities FROM areas_old',
      );
      await db.execute('DROP TABLE areas_old');
    }
  }

  String _toJsonString(dynamic data) {
    return jsonEncode(data);
  }

  dynamic _fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    return jsonDecode(jsonString);
  }

  Future<void> _upsert(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> _getAll(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<void> _delete(String tableName, String id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveArea(Area area) async {
    final map = area.toMap();
    map['state'] = _toJsonString(map['state']);
    map['cities'] = _toJsonString(map['cities']);
    await _upsert(_areasTable, map);
    _updateAreaStream();
  }

  Stream<List<Area>> getAreasStream() {
    _updateAreaStream();
    return _areasStreamController.stream;
  }

  Future<List<Area>> getAllAreas() async {
    final List<Map<String, dynamic>> maps = await _getAll(_areasTable);
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['state'] = _fromJsonString(map['state'] as String?);
      map['cities'] = _fromJsonString(map['cities'] as String?);
      return Area.fromMap(map);
    });
  }

  Future<void> deleteArea(String id) async {
    await _delete(_areasTable, id);
    _updateAreaStream();
  }

  Future<void> _updateAreaStream() async {
    final records = await getAllAreas();
    if (!_areasStreamController.isClosed) {
      _areasStreamController.add(records);
    }
  }

  Future<void> saveSubstation(Substation substation) async {
    final map = substation.toMap();
    map['voltageLevels'] = _toJsonString(map['voltageLevels']);
    await _upsert(_substationsTable, map);
    _updateSubstationStream();
  }

  Stream<List<Substation>> getSubstationsStream() {
    _updateSubstationStream();
    return _substationsStreamController.stream;
  }

  Future<List<Substation>> getAllSubstations() async {
    final List<Map<String, dynamic>> maps = await _getAll(_substationsTable);
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['voltageLevels'] = _fromJsonString(map['voltageLevels'] as String?);
      return Substation.fromMap(map);
    });
  }

  Future<void> deleteSubstation(String id) async {
    await _delete(_substationsTable, id);
    _updateSubstationStream();
  }

  Future<void> _updateSubstationStream() async {
    final records = await getAllSubstations();
    if (!_substationsStreamController.isClosed) {
      _substationsStreamController.add(records);
    }
  }

  Future<void> saveBay(Bay bay) async {
    await _upsert(_baysTable, bay.toMap());
    _updateBayStream();
  }

  Stream<List<Bay>> getBaysStream() {
    _updateBayStream();
    return _baysStreamController.stream;
  }

  Future<List<Bay>> getAllBays() async {
    final List<Map<String, dynamic>> maps = await _getAll(_baysTable);
    return List.generate(maps.length, (i) => Bay.fromMap(maps[i]));
  }

  Future<void> deleteBay(String id) async {
    await _delete(_baysTable, id);
    _updateBayStream();
  }

  Future<void> _updateBayStream() async {
    final records = await getAllBays();
    if (!_baysStreamController.isClosed) {
      _baysStreamController.add(records);
    }
  }

  Future<void> saveEquipment(Equipment equipment) async {
    final map = equipment.toMap();
    map['details'] = _toJsonString(map['details']);
    await _upsert(_equipmentTable, map);
    _updateEquipmentStream();
  }

  Stream<List<Equipment>> getEquipmentStream() {
    _updateEquipmentStream();
    return _equipmentStreamController.stream;
  }

  Future<List<Equipment>> getAllEquipment() async {
    final List<Map<String, dynamic>> maps = await _getAll(_equipmentTable);
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['details'] = _fromJsonString(map['details'] as String?);
      return Equipment.fromMap(map);
    });
  }

  Future<void> deleteEquipment(String id) async {
    await _delete(_equipmentTable, id);
    _updateEquipmentStream();
  }

  Future<void> _updateEquipmentStream() async {
    final records = await getAllEquipment();
    if (!_equipmentStreamController.isClosed) {
      _equipmentStreamController.add(records);
    }
  }

  Future<void> saveMasterEquipmentTemplate(
    MasterEquipmentTemplate template,
  ) async {
    final map = template.toMap();
    map['customFields'] = _toJsonString(map['customFields']);
    map['associatedRelays'] = _toJsonString(map['associatedRelays']);
    await _upsert(_masterEquipmentTemplatesTable, map);
    _updateMasterEquipmentTemplateStream();
  }

  Stream<List<MasterEquipmentTemplate>> getMasterEquipmentTemplatesStream() {
    _updateMasterEquipmentTemplateStream();
    return _masterEquipmentTemplatesStreamController.stream;
  }

  Future<List<MasterEquipmentTemplate>> getAllMasterEquipmentTemplates() async {
    final List<Map<String, dynamic>> maps = await _getAll(
      _masterEquipmentTemplatesTable,
    );
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['customFields'] = _fromJsonString(map['customFields'] as String?);
      map['associatedRelays'] = _fromJsonString(
        map['associatedRelays'] as String?,
      );
      return MasterEquipmentTemplate.fromMap(map);
    });
  }

  Future<void> deleteMasterEquipmentTemplate(String id) async {
    await _delete(_masterEquipmentTemplatesTable, id);
    _updateMasterEquipmentTemplateStream();
  }

  Future<void> _updateMasterEquipmentTemplateStream() async {
    final records = await getAllMasterEquipmentTemplates();
    if (!_masterEquipmentTemplatesStreamController.isClosed) {
      _masterEquipmentTemplatesStreamController.add(records);
    }
  }

  Future<void> saveDailyReading(DailyReading reading) async {
    final map = reading.toMap();
    map['readings'] = _toJsonString(map['readings']);
    await _upsert(_dailyReadingsTable, map);
    _updateDailyReadingStream();
  }

  Stream<List<DailyReading>> getDailyReadingsStream() {
    _updateDailyReadingStream();
    return _dailyReadingsStreamController.stream;
  }

  Future<List<DailyReading>> getAllDailyReadings() async {
    final List<Map<String, dynamic>> maps = await _getAll(_dailyReadingsTable);
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['readings'] = _fromJsonString(map['readings'] as String?);
      return DailyReading.fromMap(map);
    });
  }

  Future<void> deleteDailyReading(String id) async {
    await _delete(_dailyReadingsTable, id);
    _updateDailyReadingStream();
  }

  Future<void> _updateDailyReadingStream() async {
    final records = await getAllDailyReadings();
    if (!_dailyReadingsStreamController.isClosed) {
      _dailyReadingsStreamController.add(records);
    }
  }

  Future<void> saveTask(Task task) async {
    final map = task.toMap();
    map['targetEquipmentIds'] = _toJsonString(map['targetEquipmentIds']);
    map['targetReadingFields'] = _toJsonString(map['targetReadingFields']);
    map['associatedReadingIds'] = _toJsonString(map['associatedReadingIds']);
    await _upsert(_tasksTable, map);
    _updateTaskStream();
  }

  Stream<List<Task>> getTasksStream() {
    _updateTaskStream();
    return _tasksStreamController.stream;
  }

  Future<List<Task>> getAllTasks() async {
    final List<Map<String, dynamic>> maps = await _getAll(_tasksTable);
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['targetEquipmentIds'] = _fromJsonString(
        map['targetEquipmentIds'] as String?,
      );
      map['targetReadingFields'] = _fromJsonString(
        map['targetReadingFields'] as String?,
      );
      map['associatedReadingIds'] = _fromJsonString(
        map['associatedReadingIds'] as String?,
      );
      return Task.fromMap(map);
    });
  }

  Future<void> deleteTask(String id) async {
    await _delete(_tasksTable, id);
    _updateTaskStream();
  }

  Future<void> _updateTaskStream() async {
    final records = await getAllTasks();
    if (!_tasksStreamController.isClosed) {
      _tasksStreamController.add(records);
    }
  }

  Future<void> saveState(StateModel state) async {
    await _upsert(_statesTable, state.toMap());
    _updateStateStream();
  }

  Stream<List<StateModel>> getStatesStream() {
    _updateStateStream();
    return _statesStreamController.stream;
  }

  Future<List<StateModel>> getAllStates() async {
    final List<Map<String, dynamic>> maps = await _getAll(_statesTable);
    return List.generate(maps.length, (i) => StateModel.fromMap(maps[i]));
  }

  Future<void> _updateStateStream() async {
    final records = await getAllStates();
    if (!_statesStreamController.isClosed) {
      _statesStreamController.add(records);
    }
  }

  Future<void> prePopulateStates(List<StateModel> states) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var state in states) {
        await txn.insert(
          _statesTable,
          state.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    print('States pre-populated.');
    _updateStateStream();
  }

  Future<void> saveCity(CityModel city) async {
    await _upsert(_citiesTable, city.toMap());
    _updateCityStream();
  }

  Stream<List<CityModel>> getCitiesStream() {
    _updateCityStream();
    return _citiesStreamController.stream;
  }

  Future<List<CityModel>> getAllCities() async {
    final List<Map<String, dynamic>> maps = await _getAll(_citiesTable);
    return List.generate(maps.length, (i) => CityModel.fromMap(maps[i]));
  }

  Future<void> _updateCityStream() async {
    final records = await getAllCities();
    if (!_citiesStreamController.isClosed) {
      _citiesStreamController.add(records);
    }
  }

  Future<void> prePopulateCities(List<CityModel> cities) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var city in cities) {
        await txn.insert(
          _citiesTable,
          city.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    print('Cities pre-populated.');
    _updateCityStream();
  }

  Future<void> saveUserProfile(UserProfile userProfile) async {
    final map = userProfile.toMap();
    map['assignedSubstationIds'] = _toJsonString(map['assignedSubstationIds']);
    map['assignedAreaIds'] = _toJsonString(map['assignedAreaIds']);
    await _upsert(_userProfilesTable, map);
  }

  Future<UserProfile?> getUserProfileById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _userProfilesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      map['assignedSubstationIds'] = _fromJsonString(
        map['assignedSubstationIds'] as String?,
      );
      map['assignedAreaIds'] = _fromJsonString(
        map['assignedAreaIds'] as String?,
      );
      return UserProfile.fromMap(map);
    }
    return null;
  }

  Future<void> deleteUserProfile(String id) async {
    await _delete(_userProfilesTable, id);
  }

  Future<void> saveConnection(ElectricalConnection connection) async {
    final map = connection.toMap();
    map['points'] = _toJsonString(map['points']);
    await _upsert(_connectionsTable, map);
    _updateConnectionStream();
  }

  Stream<List<ElectricalConnection>> getConnectionsStream() {
    _updateConnectionStream();
    return _connectionsStreamController.stream;
  }

  Future<List<ElectricalConnection>> getAllConnections() async {
    final List<Map<String, dynamic>> maps = await _getAll(_connectionsTable);
    return List.generate(maps.length, (i) {
      final map = maps[i];
      map['points'] = _fromJsonString(map['points'] as String?);
      return ElectricalConnection.fromMap(map);
    });
  }

  Future<void> deleteConnection(String id) async {
    await _delete(_connectionsTable, id);
    _updateConnectionStream();
  }

  Future<void> _updateConnectionStream() async {
    final records = await getAllConnections();
    if (!_connectionsStreamController.isClosed) {
      _connectionsStreamController.add(records);
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _areasStreamController.close();
    _substationsStreamController.close();
    _baysStreamController.close();
    _equipmentStreamController.close();
    _masterEquipmentTemplatesStreamController.close();
    _dailyReadingsStreamController.close();
    _tasksStreamController.close();
    _statesStreamController.close();
    _citiesStreamController.close();
    _connectionsStreamController.close();
  }

  // --- SQL Parsing Methods ---
  static Future<List<StateModel>> parseStatesSql(String sqlContent) async {
    final List<StateModel> states = [];
    final RegExp regex = RegExp(
      r"INSERT INTO core_state\(id, name\)\s+VALUES\s+\(\s*(\d+),\s*'([^']+)'\s*\);",
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(sqlContent);

    for (final match in matches) {
      final id = double.parse(match.group(1)!);
      final name = match.group(2)!;
      states.add(StateModel(id: id, name: name));
    }
    return states;
  }

  static Future<List<CityModel>> parseCitiesSql(String sqlContent) async {
    final List<CityModel> cities = [];
    final RegExp regex = RegExp(
      r"INSERT INTO core_city\(id, name, state_id\)\s+VALUES\s+\(\s*(\d+),\s*'([^']+)',\s*(\d+)\s*\);",
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(sqlContent);

    for (final match in matches) {
      final id = double.parse(match.group(1)!);
      final name = match.group(2)!;
      final stateId = double.parse(match.group(3)!);
      cities.add(CityModel(id: id, name: name, stateId: stateId));
    }
    return cities;
  }
}
