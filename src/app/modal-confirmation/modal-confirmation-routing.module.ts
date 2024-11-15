import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { ModalConfirmationPageModule } from './modal-confirmation.module';

const routes: Routes = [
  {
    path: '',
    component: ModalConfirmationPageModule
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class ModalConfirmationPageRoutingModule {}
