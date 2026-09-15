// Firebase configuration for web
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyDPAzlHyBLTU83kZ6jSisEgPOjsuSwKuj0",
  authDomain: "imchat-84519.firebaseapp.com",
  projectId: "imchat-84519",
  storageBucket: "imchat-84519.appspot.com",
  messagingSenderId: "518076067996",
  appId: "1:518076067996:web:174b33c043d49536a3fd59",
  measurementId: "G-XG7W2CHTZH"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export { auth };
