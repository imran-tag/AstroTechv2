import { Component, Input, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { SharedModule } from '../../../../_globale/shared/shared.module';
import { MultiStepFormService } from '../../../../_services/multi-step-form.service';
import { TechnicienService } from '../../../../_services/techniciens/technicien.service';
import { ReferentsService } from '../../../../_services/referents/referents.service';
import { EquipeTechniciensService } from '../../../../_services/techniciens/equipe-techniciens.service';
import { MotCleService } from '../../../../_services/affaires/mot-cle.service';

@Component({
  selector: 'app-etape2',
  standalone: true,
  imports: [SharedModule],
  templateUrl: './etape2.component.html',
  styleUrl: './etape2.component.css'
})
export class Etape2Component implements OnInit {
  @Input() form!: FormGroup;

  referents: any[] = [];
  techniciens: any[] = [];
  equipes: any[] = [];
  motsClesDisponibles: any[] = [];

  selectedType: 'individuel' | 'equipe' = 'individuel';
  selectedEquipe: any = null;
  enteredKeyword: string = '';
  keywords: (string | number)[] = []; // ✅ Typage mixte : string ou number

  constructor(
    private formService: MultiStepFormService,
    private technicienService: TechnicienService,
    private referentsService: ReferentsService,
    private equipeService: EquipeTechniciensService,
    private motCleService: MotCleService
  ) {}

  ngOnInit() {
    if (!this.form) return;

    // 1. Initialiser les mots-clés depuis le formulaire
    const mots = this.form.get('motsCles')?.value;
    if (mots) {
      this.keywords = Array.isArray(mots) ? [...mots] : [];
    }

    const equipeId = this.form.get('equipeTechnicienId')?.value;
    this.selectedType = equipeId ? 'equipe' : 'individuel';

    this.loadReferents();
    this.loadTechniciens();
    this.loadEquipes();
    this.loadMotCle();

    this.form.valueChanges.subscribe(val => {
      this.formService.setStepData('step2', val);
    });
  }

  loadTechniciens() { this.technicienService.getAll().subscribe(data => this.techniciens = data); }
  loadReferents() { this.referentsService.getAll().subscribe(data => this.referents = data); }
  loadMotCle() { this.motCleService.getAll().subscribe(data => this.motsClesDisponibles = data); }

  loadEquipes() {
    this.equipeService.getAllEquipes().subscribe((res: any) => {
      this.equipes = res.data || [];
      if (this.selectedType === 'equipe') { this.updateSelectedEquipe(); }
    });
  }

  onTechnicienChange(event: any): void {
    this.selectedType = event.target.value;
    if (this.selectedType === 'individuel') {
      this.form.patchValue({ equipeTechnicienId: null });
      this.selectedEquipe = null;
    } else {
      this.form.patchValue({ technicienId: null });
    }
  }

  onEquipeSelect() {
    this.form.patchValue({ technicienId: null });
    this.updateSelectedEquipe();
  }

  private updateSelectedEquipe() {
    const id = this.form.get('equipeTechnicienId')?.value;
    if (id) {
      this.selectedEquipe = this.equipes.find(eq => eq.id === Number(id)) || null;
    }
  }

  // --- Gestion des Mots-Clés ---

  addKeyword() {
    const val = this.enteredKeyword.trim();
    if (val && !this.keywords.includes(val)) {
      this.keywords.push(val); // Ajout comme string
      this.updateFormControlKeywords();
    }
    this.enteredKeyword = '';
  }

  deleteKeyword(index: number) {
    this.keywords.splice(index, 1);
    this.updateFormControlKeywords();
  }

  private updateFormControlKeywords() {
    // ✅ On garde le tableau tel quel (mélange possible de string et number)
    this.form.get('motsCles')?.setValue([...this.keywords]);
  }
}