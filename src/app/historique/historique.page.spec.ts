import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HistoriquePage } from './historique.page';

describe('HistoriquePage', () => {
  let component: HistoriquePage;
  let fixture: ComponentFixture<HistoriquePage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(HistoriquePage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
