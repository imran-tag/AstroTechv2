import { Component, OnInit } from '@angular/core';
import { EquipeTechniciensService } from '../../_services/techniciens/equipe-techniciens.service';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SharedModule } from '../../_globale/shared/shared.module';
import { RouterModule } from '@angular/router';
import { TechnicienService } from '../../_services/techniciens/technicien.service';

// --- AJOUT DES INTERFACES POUR LE TYPAGE ---
interface Technicien {
  id: number;
  nom: string;
  prenom: string;
}

// Assurez-vous que l'interface Technicien inclut le tableau
interface Equipe {
  id: number;
  nom: string;
  chef?: any;
  techniciens: any[]; // On garantit que c'est un tableau
}



@Component({
  standalone: true, // Assurez-vous que c'est bien standalone si vous utilisez imports directement
  imports: [SharedModule, RouterModule],
  selector: 'app-equipe',
  templateUrl: './equipe.component.html',
  styleUrls: ['./equipe.component.css']
})
export class EquipeComponent implements OnInit {
  formEquipe!: FormGroup;
  
  // Typage précis au lieu de 'any'
  techniciens: Technicien[] = [];
  equipes: Equipe[] = [];
  
  loading = false;
  message = '';
  currentPage = 1;
  limit = 9;
  total = 0;
  totalPages = 0;
  searchTerm = '';

  constructor(
    private fb: FormBuilder,
    private equipeService: EquipeTechniciensService,
    private technicienService: TechnicienService
  ) { }

  ngOnInit(): void {
    this.initForm();
    this.loadTechniciens();
    this.loadEquipes();
  }

  initForm() {
    this.formEquipe = this.fb.group({
      nomEquipe: ['', Validators.required],
      chefId: ['', Validators.required],
      techniciensIds: [[], Validators.required]
    });
  }

  loadEquipes() {
    this.equipeService
      .apiGetAllWithPaginated(this.currentPage, this.limit, this.searchTerm)
      .subscribe((res: any) => {
        // Mapping des données pour s'assurer de la structure attendue par le template
        this.equipes = res.data;
        this.total = res.total;
        this.totalPages = Math.ceil(this.total / this.limit);
      });
  }

  changePage(page: number) {
    if (page < 1 || page > this.totalPages) return;
    this.currentPage = page;
    this.loadEquipes();
  }

  loadTechniciens() {
    this.technicienService.getAll().subscribe((res: any) => {
      this.techniciens = res;
    });
  }

  onSubmit() {
    if (this.formEquipe.invalid) {
      alert("⚠️ Veuillez remplir tous les champs obligatoires !");
      return;
    }

    this.loading = true;
    const formValue = this.formEquipe.value;

    const equipeData = {
      nom: formValue.nomEquipe,
      chefId: formValue.chefId
    };

    this.equipeService.createEquipe(equipeData).subscribe({
      next: (equipe: any) => {
        const equipeId = equipe.data.id;
        const ajoutPromises = formValue.techniciensIds.map((techId: number) =>
          this.equipeService.addTechnicienToEquipe(equipeId, techId).toPromise()
        );

        Promise.all(ajoutPromises).then(() => {
          this.message = '✅ Équipe créée avec succès !';
          this.formEquipe.reset();
          this.loadEquipes();
        }).catch(err => {
          console.error(err);
          this.message = '⚠️ Erreur lors de l’affectation';
        }).finally(() => this.loading = false);
      },
      error: (err) => {
        console.error(err);
        this.message = '❌ Erreur création équipe';
        this.loading = false;
      }
    });
  }

  deleteEquipe(id: number) {
    if (window.confirm('Voulez-vous vraiment supprimer cette équipe ?')) {
      this.equipeService.deleteEquipe(id).subscribe({
        next: () => this.loadEquipes(),
        error: (err) => alert('Impossible de supprimer cette équipe.')
      });
    }
  }

  
}