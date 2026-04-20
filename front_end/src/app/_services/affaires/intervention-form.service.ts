import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { FormBuilder, FormGroup } from '@angular/forms';

@Injectable({
  providedIn: 'root'
})
export class InterventionFormService {

  formStep1: FormGroup;
  formStep2: FormGroup;

  private formData = new BehaviorSubject<any>({
    step1: {},
    step2: {}
  });
  formData$ = this.formData.asObservable();

  constructor(private fb: FormBuilder) {

    // Étape 1 : Informations générales
    this.formStep1 = this.fb.group({
      numero: [0],
      titre: [''],
      client_id: [0],
      type_id: [0],
      zone_intervention_client_id: [0],
      type_client_zone_intervention: [''],
      description: ['']
    });

    // Étape 2 : Détails techniques et financiers
    this.formStep2 = this.fb.group({
      priorite: [''],
      referent_ids: [[]],
      etat: [null],
      date_butoir_realisation: [''],
      date_cloture_estimee: [''],
      motsCles: [[]], // Correction du nom (mmotsCles -> motsCles)
      montant_intervention: [0],
      montant_main_oeuvre: [0],
      montant_fournitures: [0]
    });

    // Synchro auto vers le BehaviorSubject
    this.formStep1.valueChanges.subscribe(val => this.updateSubject('step1', val));
    this.formStep2.valueChanges.subscribe(val => this.updateSubject('step2', val));
  }

  private updateSubject(step: string, data: any) {
    const current = this.formData.getValue();
    this.formData.next({ ...current, [step]: data });
  }

  setStepData(step: string, data: any) {
    if (step === 'step1') this.formStep1.patchValue(data, { emitEvent: false });
    if (step === 'step2') this.formStep2.patchValue(data, { emitEvent: false });
    this.updateSubject(step, data);
  }

  getFormData() {
    return this.formData.getValue();
  }

  resetAllForms() {
    this.formStep1.reset({ numero: 0, client_id: 0, type_id: 0, zone_intervention_client_id: 0 });
    this.formStep2.reset({ referent_ids: [], motsCles: [], montant_intervention: 0, montant_main_oeuvre: 0, montant_fournitures: 0 });
    this.formData.next({ step1: {}, step2: {} });
  }
}