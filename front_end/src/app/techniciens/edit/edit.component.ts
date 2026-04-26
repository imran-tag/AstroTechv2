import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SharedModule } from '../../_globale/shared/shared.module';
import { TechnicienService } from '../../_services/techniciens/technicien.service';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

@Component({
  selector: 'app-edit',
  imports: [SharedModule, RouterModule],
  templateUrl: './edit.component.html',
  styleUrl: './edit.component.css'
})
export class EditComponent {

  technicienForm!: FormGroup;
  showPassword: boolean = false;
  id!: number;

  get isEdit(): boolean { return !!this.id; }

  constructor(
    private fb: FormBuilder,
    private technicienService: TechnicienService,
    private router: Router,
    private route: ActivatedRoute
  ) { }

  ngOnInit(): void {
    // 1️⃣ Récupérer l'ID depuis l'URL
    this.id = +this.route.snapshot.params['id'];

    // 2️⃣ Initialiser le formulaire
    this.technicienForm = this.fb.group({
      nom: ['', Validators.required],
      prenom: ['', Validators.required],
      dateNaissance: [''],
      adresse: [''],
      telephone: ['', Validators.required],
      email: [''],
      pwd: ['', Validators.required],
      specialite: [''],
      certifications: [''],
      experience: [null],
      zoneIntervention: [''],
      dateEmbauche: [''],
      typeContrat: [''],
      salaire: [null],
      statut: ['Actif']
    });

    // 3️⃣ Charger les données existantes
    if (this.id) {
      this.technicienService.getItemById(this.id).subscribe({
        next: (data) => {
          // convertir les dates au bon format
          if (data.dateNaissance)
            data.dateNaissance = this.formatDate(data.dateNaissance);

          if (data.dateEmbauche)
            data.dateEmbauche = this.formatDate(data.dateEmbauche);

          this.technicienForm.patchValue(data);
        },
        error: (err) => console.error(err)
      })
    }
  }//fin if

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toISOString().split('T')[0]; // ✅ "1986-06-26"
  }

  // 4️⃣ Sauvegarder les modifications
  editTechnicien() {
    if (this.technicienForm.valid) {
      this.technicienService.update(this.technicienForm.value, this.id).subscribe({
        next: () => {
          alert('✅ Technicien modifié avec succès !');
          this.router.navigate(['/techniciens/list']); // redirection vers la liste
        },
        error: (err) => console.error('❌ Erreur lors de la modification :', err)
      });
    }
    else {
      // Show a warning message
      alert("⚠️ Veuillez remplir tous les champs obligatoires avant de soumettre le formulaire !");

      // Optionally, mark all fields as touched to highlight validation errors in the UI
      this.technicienForm.markAllAsTouched();
    }
  }

  addTechnicien() {
    if (this.technicienForm.valid) {
      this.technicienService.create(this.technicienForm.value).subscribe(result => {
        this.router.navigate(['/techniciens/list']);
      });
    } else {
      // Show a warning message
      alert("⚠️ Veuillez remplir tous les champs obligatoires avant de soumettre le formulaire !");

      // Optionally, mark all fields as touched to highlight validation errors in the UI
      this.technicienForm.markAllAsTouched();
    }
  }

  onSubmit() {
    if (this.id)
      this.editTechnicien();
    else
      this.addTechnicien();
  }

}
