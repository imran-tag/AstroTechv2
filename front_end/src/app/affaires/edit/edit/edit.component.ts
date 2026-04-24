import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { lastValueFrom } from 'rxjs';

import { Etape1Component } from '../components/etape1/etape1.component';
import { Etape2Component } from '../components/etape2/etape2.component';
import { Etape3Component } from '../components/etape3/etape3.component';

import { MultiStepFormService } from '../../../_services/multi-step-form.service';
import { AffairesService } from '../../../_services/affaires/affaires.service';
import { FichiersService } from '../../../_services/fichiers/fichiers.service';

@Component({
  selector: 'app-edit',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    Etape1Component,
    Etape2Component,
    Etape3Component
  ],
  templateUrl: './edit.component.html',
  styleUrls: ['./edit.component.css']
})
export class EditComponent implements OnInit {
  step = 1;
  loading = false;
  isEdit = false;
  affaireId!: number;
  formReady = false;

  constructor(
    public formService: MultiStepFormService,
    private affairesService: AffairesService,
    private fichiersService: FichiersService,
    private route: ActivatedRoute,
    private router: Router
  ) { }

  async ngOnInit() {
    this.formService.resetAllForms();
    const idParam = this.route.snapshot.paramMap.get('id');

    if (idParam) {
      this.isEdit = true;
      this.affaireId = Number(idParam);
      await this.loadAffaireData();
    } else {
      this.formReady = true;
    }
  }

  async loadAffaireData() {
    try {
      const res: any = await lastValueFrom(this.affairesService.getItemById(this.affaireId));
      const a = res.data;
      const formatDate = (d: string | null) => d ? d.split('T')[0] : '';

      this.formService.formStep1.patchValue({
        reference: a.reference,
        titre: a.titre,
        client_id: a.client_id,
        zone_intervention_client_id: a.zone_intervention_client_id ? Number(a.zone_intervention_client_id) : null,
        type_client_zone_intervention: a.type_client_zone_intervention,
        description: a.description
      });

      this.formService.formStep2.patchValue({
        etatLogement: a.etatLogement,
        referentId: a.referents ? a.referents.map((r: any) => r.id || r) : [],
        // ✅ On récupère les IDs ou les labels existants
        //motsCles: a.motsCles ? a.motsCles.map((m: any) => m.id || m) : [],
        motsCles: a.motsCles || [],
        technicienId: a.technicienId ? Number(a.technicienId) : null,
        equipeTechnicienId: a.equipeTechnicienId ? Number(a.equipeTechnicienId) : null,
        dateDebut: formatDate(a.dateDebut),
        dateFin: formatDate(a.dateFin),
        dureePrevueHeures: a.dureePrevueHeures,
        dureePrevueMinutes: a.dureePrevueMinutes,
        memo: a.memo
      });

      this.formService.formStep3.patchValue({
        fichiers: [],
        memoPiecesJointes: a.memoPiecesJointes
      });

      this.formReady = true;
    } catch (err) {
      console.error("Erreur chargement affaire", err);
      this.router.navigate(['/affaires/list']);
    }
  }

  nextStep() { if (this.step < 3) this.step++; }
  previousStep() { if (this.step > 1) this.step--; }

  /**
   * Méthode d'upload des fichiers adaptée à la structure du formulaire
   */
  async uploadFiles(idAffaire: number, files: File[]) {
    if (!files || files.length === 0) return;

    console.log(`Début de l'upload pour l'affaire #${idAffaire}`);

    for (const file of files) {
      try {
        const fd = new FormData();
        fd.append('files', file); // 'files' doit correspondre au nom attendu par votre middleware Multer
        fd.append('idAffaire', idAffaire.toString());

        await lastValueFrom(this.fichiersService.uploadFiles(fd));
        console.log(`Fichier ${file.name} envoyé avec succès.`);
      } catch (err) {
        console.error(`Erreur upload pour le fichier ${file.name}`, err);
      }
    }
  }

  // async submit() {
  //   const data = this.formService.getFormData();
  //   // Fusion des données des 3 étapes
  //   const all = { ...data.step1, ...data.step2, ...data.step3 };

  //   const affaireData = {
  //     ...all,
  //     // Conversion des IDs classiques
  //     client_id: all.client_id ? Number(all.client_id) : null,
  //     technicienId: all.technicienId ? Number(all.technicienId) : null,
  //     equipeTechnicienId: all.equipeTechnicienId ? Number(all.equipeTechnicienId) : null,
  //     referents: Array.isArray(all.referentId) ? all.referentId.map(Number).filter((id: any) => !isNaN(id)) : [],

  //     // ✅ SOLUTION OPTIMISÉE POUR LE FORMAT [3, 1, "mmm"]
  //     motsCles: Array.isArray(all.motsCles)
  //       ? all.motsCles
  //         .filter((item: any) => item !== null && item !== undefined) // Supprime les entrées invalides
  //         .map((item: any) => {
  //           // Si c'est déjà un nombre ou une string simple (cas où ng-select aurait déjà aplati)
  //           if (typeof item !== 'object') {
  //             const num = Number(item);
  //             return !isNaN(num) ? num : item;
  //           }
  //           // Si c'est un objet (cas Solution 1 de ma réponse précédente)
  //           // On prend l'ID s'il existe, sinon le libelle
  //           return item.id !== undefined ? item.id : item.libelle;
  //         })
  //       : [],

  //     dateDebut: all.dateDebut || null,
  //     dateFin: all.dateFin || null
  //   };

  //   console.log("Données envoyées à l'API :", affaireData);

  //   this.loading = true;
  //   try {
  //     if (this.isEdit) {
  //       await lastValueFrom(this.affairesService.update(this.affaireId, affaireData));
  //     } else {
  //       const res: any = await lastValueFrom(this.affairesService.create(affaireData));
  //       // ... gestion des fichiers
  //     }
  //     this.formService.resetAllForms();
  //     this.router.navigate(['/affaires/list']);
  //   } catch (err) {
  //     console.error("Erreur lors de la sauvegarde", err);
  //   } finally {
  //     this.loading = false;
  //   }
  // }

  async submit() {
    const data = this.formService.getFormData();
    const all = { ...data.step1, ...data.step2, ...data.step3 };

    // On récupère les fichiers séparément avant la conversion des données
    const filesToUpload = all.fichiers || [];

    const affaireData = {
      ...all,
      client_id: all.client_id ? Number(all.client_id) : null,
      technicienId: all.technicienId ? Number(all.technicienId) : null,
      equipeTechnicienId: all.equipeTechnicienId ? Number(all.equipeTechnicienId) : null,
      referents: Array.isArray(all.referentId) ? all.referentId.map(Number).filter((id: any) => !isNaN(id)) : [],
      motsCles: Array.isArray(all.motsCles)
        ? all.motsCles
          .filter((item: any) => item !== null && item !== undefined)
          .map((item: any) => {
            if (typeof item !== 'object') {
              const num = Number(item);
              return !isNaN(num) ? num : item;
            }
            return item.id !== undefined ? item.id : item.libelle;
          })
        : [],
      dateDebut: all.dateDebut || null,
      dateFin: all.dateFin || null
    };

    this.loading = true;
    try {
      let currentAffaireId = this.affaireId;

      if (this.isEdit) {
        // Mise à jour
        await lastValueFrom(this.affairesService.update(this.affaireId, affaireData));
      } else {
        // Création
        const res: any = await lastValueFrom(this.affairesService.create(affaireData));
        // On récupère l'ID généré par le backend (souvent dans res.id ou res.data.id)
        currentAffaireId = res.id || (res.data ? res.data.id : null);
      }

      // ✅ Gestion des fichiers après la création/modification réussie
      if (currentAffaireId && filesToUpload.length > 0) {
        await this.uploadFiles(currentAffaireId, filesToUpload);
      }

      this.formService.resetAllForms();
      this.router.navigate(['/affaires/list']);
    } catch (err) {
      console.error("Erreur lors de la sauvegarde", err);
    } finally {
      this.loading = false;
    }
  }
}