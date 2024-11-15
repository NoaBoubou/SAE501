import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { Capacitor } from '@capacitor/core';
import { initializeAuth, indexedDBLocalPersistence } from 'firebase/auth';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'AIzaSyAe7ZfllWgiZBxV4i8TsEIWRfyKEie7UI0',
  authDomain: 'sae501-14837.firebaseapp.com',
  projectId: 'sae501-14837',
  storageBucket: 'sae501-14837.firebasestorage.app',
  messagingSenderId: '600568281242',
  appId: '1:600568281242:web:79f11e6714b2a1cbb34723',
  measurementId: 'G-M5CXYTVLL0',
};

const app = initializeApp(firebaseConfig);

function whichAuth() {
  let auth;
  if (Capacitor.isNativePlatform()) {
    auth = initializeAuth(app, {
      persistence: indexedDBLocalPersistence,
    });
  } else {
    auth = getAuth();
  }
  return auth;
}

export const auth = whichAuth();

export const db = getFirestore(app);
