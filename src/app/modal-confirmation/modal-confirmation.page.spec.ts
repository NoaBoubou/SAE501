import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ModalConfirmationPage } from './modal-confirmation.page';

describe('ModalConfirmationPage', () => {
  let component: ModalConfirmationPage;
  let fixture: ComponentFixture<ModalConfirmationPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(ModalConfirmationPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
