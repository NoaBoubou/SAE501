import { Component } from '@angular/core';
import { HistoriqueService } from '../services/historique/historique.service';

@Component({
  selector: 'app-historique',
  templateUrl: './historique.page.html',
  styleUrls: ['./historique.page.scss'],
})
export class HistoriquePage {
  histos: any[] = [];
  data: any[] = []; 

  constructor(private historique: HistoriqueService) {}

  async ngOnInit() {
    this.histos = await this.historique.getHistorique();
    this.data = [...this.histos]; 
  }

  handleInput(e: any) {
    const recherche = e.target.value.toLowerCase();
    
    this.data = this.histos.filter(
      (histo) =>
        histo.object_class.toLowerCase().includes(recherche) ||
        histo.confidence.toString().includes(recherche) ||
        histo.date.toLowerCase().includes(recherche)
    );
  }
}
