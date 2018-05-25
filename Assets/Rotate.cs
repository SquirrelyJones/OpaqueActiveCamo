using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour {

	public Vector3 rotationVelocity = Vector3.zero;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {

		//Quaternion rotation = Quaternion.Euler (rotationVelocity);
		this.transform.Rotate (rotationVelocity * Time.deltaTime);

	}
}
