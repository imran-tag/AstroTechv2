import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { FormBuilder, FormGroup } from '@angular/forms';

@Injectable({
  providedIn: 'root'
})
export class MultiStepFormService {

  formStep1: FormGroup;
  formStep2: FormGroup;
  formStep3: FormGroup;

  private formData = new BehaviorSubject<any>({});
  formData$ = this.formData.asObservable();

  constructor(private fb: FormBuilder) {
    // Initialisation des formulaires
    this.formStep1 = this.fb.group({
      reference: [''],
      titre: [''],
      client_id: [null],
      zone_intervention_client_id: [null],
      type_client_zone_intervention	: [''],
      description: ['']
    });

    this.formStep2 = this.fb.group({
      etatLogement: [''],
      referentId: [[]],
      motsCles: [[] as (string | number)[]],
      technicienId: [null],
      equipeTechnicienId: [null],
      equipeId: [''],
      dateDebut: [''],
      dateFin: [''],
      dureePrevueHeures: [''],
      dureePrevueMinutes: [''],
      memo: ['']
    });

    this.formStep3 = this.fb.group({
      fichiers: [[]],
      memoPiecesJointes: ['']
    });

    // Synchroniser automatiquement les FormGroups vers formData
    this.formStep1.valueChanges.subscribe(val => this.setStepData('step1', val));
    this.formStep2.valueChanges.subscribe(val => this.setStepData('step2', val));
    this.formStep3.valueChanges.subscribe(val => this.setStepData('step3', val));
  }

  setStepData(step: string, data: any) {
    const current = this.formData.getValue();
    this.formData.next({ ...current, [step]: data });
  }

  getFormData() {
    // Retourne toujours les dernières valeurs patchées des FormGroups
    return {
      step1: this.formStep1.value,
      step2: this.formStep2.value,
      step3: this.formStep3.value
    };
  }

   /** 
   * Réinitialise tous les formulaires et vide le formData 
   */
  resetAllForms() {
    // 🔹 Reset chaque FormGroup
    this.formStep1.reset({
      reference: '',
      titre: '',
      client_id: null,
      zone_intervention_client_id: null,
      type_client_zone_intervention	: '',
      description: ''
    });

    this.formStep2.reset({
      etatLogement: '',
      referentId: [],
      motsCles: [[]],
      technicienId: null,
      equipeTechnicienId: null,
      equipeId: '',
      dateDebut: '',
      dateFin: '',
      dureePrevueHeures: '',
      dureePrevueMinutes: '',
      memo: ''
    });

    this.formStep3.reset({
      fichiers: [],
      memoPiecesJointes: ''
    });

    // 🔹 Vider le BehaviorSubject
    this.formData.next({
      step1: {},
      step2: {},
      step3: {}
    });
  }
}
