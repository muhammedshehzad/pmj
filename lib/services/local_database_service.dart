import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pmj_application/models/person_model.dart';
import 'package:pmj_application/services/image_cache_service.dart';
import 'package:pmj_application/services/sqlite_database_service.dart';

import '../models/donation_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  final SQLiteDatabaseService _sqliteDb = SQLiteDatabaseService();

  bool get isInitialized => _sqliteDb.isInitialized;

  factory LocalDatabaseService() {
    return _instance;
  }

  LocalDatabaseService._internal();

  Future<void> init() async {
    await _sqliteDb.init();
  }

  // Clear all local data (SQLite + image cache)
  Future<void> clearAllData() async {
    await _sqliteDb.clearAllData();
  }

  // Delete a donation entry from local cache by its Firestore document path
  Future<void> deleteDonationByDocumentPath(String documentPath) async {
    await _sqliteDb.deleteDonationByDocumentPath(documentPath);
  }

  // Check if device is connected to the internet
  Future<bool> get isConnected async {
    return await _sqliteDb.isConnected;
  }

  // Watch all donations in real-time
  Stream<List<Donation>> watchDonations({String? query}) {
    return _sqliteDb.watchDonations(query: query);
  }

  // Get a single person by ID
  Future<Person?> getPersonById(int id) async {
    return await _sqliteDb.getPersonById(id);
  }

  Future<void> syncWithFirestore() async {
    await _sqliteDb.syncWithFirestore();
  }

  // Force refresh of all data streams
  Future<void> refreshData() async {
    await _sqliteDb.syncWithFirestore();
  }

  // Check if database has data
  Future<bool> databaseExists() async {
    return await _sqliteDb.databaseExists();
  }

  // Get all people with optional search query
  Stream<List<Person>> watchPeople({String query = ''}) {
    return _sqliteDb.watchPeople(query: query);
  }

  // Add or update a person
  Future<void> upsertPerson(Person person) async {
    await _sqliteDb.upsertPerson(person);
  }

  // Delete a person
  Future<Person?> deletePerson(int id) async {
    return await _sqliteDb.deletePerson(id);
  }
}