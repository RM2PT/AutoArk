package com.rm2pt.generator.autoark

import com.google.inject.Inject
import com.google.inject.Provider

import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException
import org.eclipse.core.commands.IHandler
import org.eclipse.core.resources.IFile
import org.eclipse.core.runtime.NullProgressMonitor
import org.eclipse.emf.common.util.URI
import org.eclipse.jface.text.TextSelection
import org.eclipse.jface.viewers.IStructuredSelection
import org.eclipse.jface.wizard.WizardDialog
import org.eclipse.swt.widgets.Shell
import org.eclipse.ui.handlers.HandlerUtil
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.xtext.generator.GeneratorContext
import org.eclipse.xtext.resource.SynchronizedXtextResourceSet
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.ui.resource.IResourceSetProvider

class CodeGeneratorHandler extends AbstractHandler implements IHandler {
	@Inject CodeGenerator generator
	@Inject Provider<EclipseResourceFileSystemAccess2> fileAccessProvider
	@Inject IResourceSetProvider resourceSetProvider

	override execute(ExecutionEvent event) throws ExecutionException {
		var selection = HandlerUtil.getCurrentSelection(event)
		var shell = HandlerUtil.getActiveShell(event)
		if (selection instanceof IStructuredSelection) {
			var structuredSelection = selection as IStructuredSelection
			var firstElement = structuredSelection.firstElement
			if (firstElement instanceof IFile) {
				var wizard = findWizard(firstElement as IFile, shell)
				generateCode(wizard, firstElement as IFile)
			}
		} else if (selection instanceof TextSelection) {
			var activeEditor = HandlerUtil.getActiveEditor(event)
			val file = activeEditor.editorInput.getAdapter(IFile)
			var wizard = findWizard(file, shell)
			generateCode(wizard, file)
		}
		return null
	}

	def findWizard(IFile file, Shell shell) {
		var wizard = new MyInfoWizard(file.project.name)
		var dialog = new WizardDialog(shell, wizard)
		dialog.open
		return wizard
	}

	def generateCode(MyInfoWizard wizard, IFile file) {
		val fsa = fileAccessProvider.get
		fsa.project = wizard.myProject
		fsa.outputPath = "./"
		fsa.monitor = new NullProgressMonitor
		val uri = URI.createPlatformResourceURI(file.fullPath.toString, true)
		var xrs = resourceSetProvider.get(wizard.myProject) as SynchronizedXtextResourceSet
		xrs.addLoadOption(XtextResource.OPTION_RESOLVE_ALL, Boolean.TRUE)
		var rsc = xrs.getResource(uri, true)
		generator.wizard = wizard
		generator.doGenerate(rsc, fsa, new GeneratorContext)
	}

	override isEnabled() {
		return true
	}
}
