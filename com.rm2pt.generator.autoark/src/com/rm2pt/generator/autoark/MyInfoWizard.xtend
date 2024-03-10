package com.rm2pt.generator.autoark

import org.eclipse.core.resources.IProject
import org.eclipse.core.runtime.CoreException
import org.eclipse.jface.wizard.IWizardPage
import org.eclipse.ui.dialogs.WizardNewProjectCreationPage
import org.eclipse.ui.wizards.newresource.BasicNewProjectResourceWizard

class MyInfoWizard extends BasicNewProjectResourceWizard {
	WizardNewProjectCreationPage infoPage
	DetailWizardPage detailPage
	IProject myProject
	String projectName
	String backendURL
	String apiVersion

	new(String projectName) {
		this.projectName = projectName
	}

	override addPages() {
		infoPage = new WizardNewProjectCreationPage("Create ArkUI Project")
		infoPage.setTitle("Create ArkUI Project")
		infoPage.setDescription("Set project name and location")
		infoPage.setInitialProjectName(projectName + "ArkUIProject")
		infoPage.setPageComplete(true)
		addPage(infoPage)
		detailPage = new DetailWizardPage
		detailPage.setPageComplete(true)
		addPage(detailPage)
	}

	override getNextPage(IWizardPage currentPage) { return currentPage == infoPage ? detailPage : null }

	override performFinish() {
		try {
			myProject = infoPage.projectHandle
			backendURL = detailPage.backendURL
			apiVersion = detailPage.APIVersion
			if (!myProject.exists) {
				myProject.create(null)
			}
			myProject.open(null)
		} catch (CoreException event) {
			event.printStackTrace
		}
		return true
	}

	def getMyProject() { return myProject }

	def getBackendURL() { return backendURL }

	def getAPIVersion() { return apiVersion }

	def getProjectName() { return projectName }
}
