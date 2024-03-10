package com.rm2pt.generator.autoark

import org.eclipse.jface.wizard.WizardPage
import org.eclipse.swt.SWT
import org.eclipse.swt.events.ModifyEvent
import org.eclipse.swt.events.ModifyListener
import org.eclipse.swt.layout.GridData
import org.eclipse.swt.layout.GridLayout
import org.eclipse.swt.widgets.Combo
import org.eclipse.swt.widgets.Composite
import org.eclipse.swt.widgets.Label
import org.eclipse.swt.widgets.Text

class DetailWizardPage extends WizardPage {
	Text text
	Combo combo

	new() {
		super("Project Configuration")
		setTitle("Project Configuration")
		setDescription("Provide project configuration information")
	}

	override createControl(Composite parent) {
		var container = new Composite(parent, SWT.NONE)
		container.setLayout(new GridLayout(2, false))
		setControl(container)
		text = addText(container, "Backend URL", "127.0.0.1:8080")
		combo = addCombo(container, "API Version", #["8", "9"], 0)
	}

	def addText(Composite container, String key, String value) {
		var label = new Label(container, SWT.NONE)
		label.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1))
		label.setText(key)
		var text = new Text(container, SWT.BORDER)
		text.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1))
		text.setText(value)
		text.addModifyListener(new ModifyListener {
			override modifyText(ModifyEvent event) {
				setPageComplete(!backendURL.isEmpty)
			}
		})
		return text
	}

	def addCombo(Composite container, String key, String[] items, int select) {
		var label = new Label(container, SWT.NONE)
		label.setLayoutData(new GridData(SWT.RIGHT, SWT.CENTER, false, false, 1, 1))
		label.setText(key)
		var combo = new Combo(container, SWT.NONE)
		combo.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1))
		combo.setItems(items)
		combo.select(select)
		return combo
	}

	def getBackendURL() { return text !== null ? text.text : "" }

	def getAPIVersion() { return combo !== null ? combo.text : "" }
}
