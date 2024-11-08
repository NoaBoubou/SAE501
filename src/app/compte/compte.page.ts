import { Component, OnInit } from '@angular/core';

import { ModalController } from '@ionic/angular';
import { ModalExampleComponent } from '../modal-confirmation/modal-confirmation.page';

@Component({
  selector: 'app-compte',
  templateUrl: './compte.page.html',
  styleUrls: ['./compte.page.scss'],
})
export class ComptePage implements OnInit {

  constructor(private modalCtrl: ModalController) { }

  ngOnInit() {
  }

  async openModal() {
    const modal = await this.modalCtrl.create({
      component: ModalExampleComponent,
    });
    modal.present();

    const { data, role } = await modal.onWillDismiss();

    if (role === 'confirm') {
      console.log("compte supprimé");
    }
  }
}
