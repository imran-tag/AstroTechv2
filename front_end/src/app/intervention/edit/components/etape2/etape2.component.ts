import { Component, Input, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { SharedModule } from '../../../../_globale/shared/shared.module';
import { InterventionFormService } from '../../../../_services/affaires/intervention-form.service';
import { ReferentsService } from '../../../../_services/referents/referents.service';
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

  referentsList: any[] = [];
  motsClesDisponibles: any[] = [];

  constructor(
    private formService: InterventionFormService,
    private referentService: ReferentsService,
    private motCleService: MotCleService
  ) { }

  // ngOnInit() {
  //   if (!this.form) return;

  //   this.loadReferents();

  //   // On charge les mots-clés et on restaure les données seulement après
  //   this.motCleService.getAll().subscribe({
  //     next: (data) => {
  //       this.motsClesDisponibles = data || [];

  //       // Restauration des données sauvegardées
  //       const savedData = this.formService.getFormData()['step2'];
  //       if (savedData) {
  //         this.form.patchValue(savedData);
  //       }
  //     },
  //     error: (err) => console.error('Erreur API Mots-clés:', err)
  //   });
  // }

  ngOnInit() {
    if (!this.form) return;

    console.log('** Bonjour **', this.form);


    this.loadReferents();

    // 1. Chargement des mots-clés de référence depuis l'API
    this.loadMotCle();
  }

  loadMotCle() {
    this.motCleService.getAll().subscribe({
      next: (data) => {
        this.motsClesDisponibles = data || [];

        // 2. Récupération des données sauvegardées (via le service ou l'édition)
        const savedData = this.formService.getFormData()['step2'];

        if (savedData) {
          // 🔹 LOGIQUE CRUCIALE : 
          // Si 'motsCles' contient des objets (motsClesDetails), 
          // on extrait l'ID ou le libellé pour que le formulaire soit valide.
          if (savedData.motsCles && Array.isArray(savedData.motsCles)) {
            savedData.motsCles = savedData.motsCles.map((item: any) => {
              // Si c'est un objet venant de motsClesDetails {id, libelle}
              if (item && typeof item === 'object') {
                return item.id ? item.id : item.libelle;
              }
              // Sinon on garde la valeur brute (ID ou string)
              return item;
            });
          }

          // 3. Application des valeurs au formulaire
          this.form.patchValue(savedData);
        }
      },
      error: (err) => console.error('Erreur API Mots-clés:', err)
    });
  }

  loadReferents() {
    this.referentService.getAll().subscribe({
      next: (res: any) => this.referentsList = res || [],
      error: (err) => console.error('Erreur API Référents:', err)
    });
  }

  // Permet d'ajouter des tags qui ne sont pas dans la liste
  addCustomTag = (term: string) => term;

  saveStep() {
    if (this.form.valid) {
      this.formService.setStepData('step2', this.form.value);
    } else {
      this.form.markAllAsTouched();
    }
  }

  // Ajoute cette fonction pour résoudre l'erreur NG9
  compareFn(item: any, selected: any) {
    if (!item || !selected) return false;
    // Si ce sont des objets, on compare l'ID ou le libellé
    if (typeof item === 'object' && typeof selected === 'object') {
      return item.id === selected.id || item.libelle === selected.libelle;
    }
    // Si l'un est une string/ID et l'autre un objet
    return item === selected || item.id === selected || item.libelle === selected;
  }

}