import { Injectable } from '@angular/core';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class HistoriqueService {
  private docRef = 'Users';

  constructor() {}

  async getHistorique(): Promise<any[]> {
    const histo: any[] = [];
    const userSnapshot = await getDocs(collection(db, this.docRef));

    for (let userDoc of userSnapshot.docs) {
      const historiqueSnapshot = await getDocs(
        collection(db, this.docRef, userDoc.id, 'Historique')
      );

      historiqueSnapshot.forEach((histoDoc) => {
        histo.push({ id: histoDoc.id, ...histoDoc.data() });
      });
    }

    return histo;
  }
}
